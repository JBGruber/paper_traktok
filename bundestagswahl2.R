library(traktok)
library(tidyverse)
# selected accounts
accounts <- c(
  "CDU/CSU" = "insidecdu",
  "Friedrich Merz" = "merzcdu",
  "AfD" = "afdfraktionimbundestag",
  "Alice Weidel" = "alice_weidel_afd",
  "SPD" = "deinespd",
  "Olaf Scholz" = "teamolafscholz",
  "GRÜNE" = "diegruenen",
  "Robert Habeck" = "roberthabeck",
  "Die Linke" = "die.linke",
  "Heidi Reichinnek" = "heidireichinnek",
  "Jan van Aken" = "jan.van.aken",
  "BSW" = "bsw.bund",
  "Sahra Wagenknecht" = "sahra.wagenknecht",
  "FDP" = "fdp",
  "Christian Lindner" = "c_lindner"
)

# from when the coalition ended to election date
since <- "2024-11-07"
to <- "2025-02-24"
# we need 30 day windows to query the API
dates_from <- seq.Date(
  from = as.Date(since),
  to = as.Date(to),
  by = "31 day"
)
dates_to <- dates_from + 30
# we want the last window to end at to
dates_to[length(dates_to)] <- as.Date(to)

account_in_query <- query() |>
  query_or(
    field_name = "username",
    operation = "IN",
    field_values = accounts
  )

account_videos_in <- map2(dates_from, dates_to, function(from, to) {
  tt_search_api(
    query = account_in_query,
    start_date = from,
    end_date = to,
    verbose = FALSE
  )
}, .progress = TRUE) |>
  bind_rows()

saveRDS(account_videos_in, "bundestag-videos_in-query.rds")

account_videos_eq <- map2(dates_from, dates_to, function(from, to) {
  map(accounts, \(a) {
    message("Account: ", a, ". From: ", from, "; to: ", to)
    query() |>
      query_or(
        field_name = "username",
        operation = "EQ",
        field_values = a
      ) |>
      tt_search_api(
        start_date = from,
        end_date = to,
        verbose = FALSE
      )
  }) |>
    dplyr::bind_rows()
}, .progress = TRUE) |>
  dplyr::bind_rows()

saveRDS(account_videos_eq, "bundestag-videos_eq-query.rds")

account_videos_in <- readRDS("bundestag-videos_in-query.rds") |>
  mutate(query_method = "in")
account_videos_eq <- readRDS("bundestag-videos_eq-query.rds") |>
  mutate(query_method = "eq")


account_counts <- bind_rows(account_videos_in, account_videos_eq) |>
  count(week = floor_date(create_time, "weeks"), query_method) |>
  complete(week, query_method, fill = list(n = 0))

bounds <- account_counts %>%
  pivot_wider(names_from = query_method, values_from = n) %>%
  mutate(
    ymax = pmax(eq, `in`),
    ymin = pmin(eq, `in`),
    fill = eq >= `in`
  )


account_counts |>
  ggplot(aes(x = week, y = n, colour = query_method)) +
  geom_point(aes(x = week + ifelse(query_method == "eq", -1, 1) * 21600), size = 2, alpha = 0.8) +
  geom_line(aes(linetype = query_method)) +
  scale_color_viridis_d() +
  theme_minimal() +
  labs(x = NULL, y = NULL, linetype = NULL, colour = "Query Method") +
  scale_y_continuous(limits = c(0, max(account_counts$n))) +
  guides(linetype = "none") +
  theme(
    legend.position = "inside",
    legend.position.inside = c(0.1, 0.7)
  )


account_videos_scrape <- accounts |>
  map_chr(function(account) {
    tt_user_videos_hidden(
      username = account,
      solve_captchas = TRUE,
      return_urls = TRUE
    )
  })


account_videos_hidden_api <- tt_videos_hidden(
  video_urls = account_videos$video_id,
  save_video = TRUE,
  overwrite = FALSE,
  dir = "bundestag_vids",
  cache_dir = "bundestag_vids/json"
)

saveRDS(account_videos_hidden_api, "bundestag_videos_hidden_api.rds")
