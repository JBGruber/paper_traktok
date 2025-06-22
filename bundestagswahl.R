library(traktok)
library(tidyverse)
accounts <- c(
  "CDU/CSU" = "https://www.tiktok.com/@insidecdu",
  "Friedrich Merz" = "https://www.tiktok.com/@merzcdu",
  "AfD" = "https://www.tiktok.com/@afdfraktionimbundestag",
  "Alice Weidel" = "https://www.tiktok.com/@alice_weidel_afd",
  "SPD" = "https://www.tiktok.com/@deinespd",
  "Olaf Scholz" = "https://www.tiktok.com/@teamolafscholz",
  "GRÜNE" = "https://www.tiktok.com/@diegruenen",
  "Robert Habeck" = "https://www.tiktok.com/@roberthabeck",
  "Die Linke" = "https://www.tiktok.com/@die.linke",
  "Heidi Reichinnek" = "https://www.tiktok.com/@heidireichinnek",
  "Jan van Aken" = "https://www.tiktok.com/@jan.van.aken",
  "BSW" = "https://www.tiktok.com/@bsw.bund",
  "Sahra Wagenknecht" = "https://www.tiktok.com/@sahra.wagenknecht",
  "FDP" = "https://www.tiktok.com/@fdp",
  "Christian Lindner" = "https://www.tiktok.com/@c_lindner"
)

account_videos <- accounts |>
  str_remove("https://www.tiktok.com/@") |>
  tt_user_videos_api(since = "2024-11-07", to = "2025-02-24")

saveRDS(account_videos, "bundestag_videos.rds")

since <- "2024-11-07"
to <- "2025-02-24"
dates_from <- seq.Date(
  from = as.Date(since),
  to = as.Date(to),
  by = "31 day"
)
dates_to <- dates_from + 30
# we want the last window to end today
dates_to[length(dates_to)] <- as.Date(to)

account_videos2 <- accounts |>
  str_remove("https://www.tiktok.com/@") |>
  map(function(account) {
    purrr::map2(dates_from, dates_to, function(from, to) {
      out <- query() |>
        query_or(
          field_name = "username",
          operation = "EQ",
          field_values = account
        ) |>
        tt_search_api(
          start_date = from,
          end_date = to,
          verbose = FALSE
        )
      if (nrow(out) > 0) {
        return(out)
      }
    }) |>
      dplyr::bind_rows()
  }) |>
  dplyr::bind_rows()

saveRDS(account_videos2, "bundestag_videos2.rds")

account_videos_in <- readRDS("bundestag_videos.rds") |>
  mutate(query_method = "in")
account_videos_eq <- readRDS("bundestag_videos2.rds") |>
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
  geom_point() +
  geom_line() +
  geom_ribbon(data = bounds, aes(xymin = ymin, ymax = ymax, fill = fill), alpha = 0.4, inherit.aes = FALSE) +
  theme_minimal() +
  labs(x = NULL, y = NULL, colour = "Query Method") +
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
