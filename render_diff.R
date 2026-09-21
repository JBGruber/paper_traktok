#!/usr/bin/env Rscript
# render_diff.R -- PDF with all changes since the submitted version marked up
#
# Renders paper_traktok_old.qmd (the submitted version) and paper_traktok.qmd
# with the ccr-pdf format, runs latexdiff on the two .tex files and compiles
# the result to paper_traktok_diff.pdf (additions blue/underlined, deletions
# red/struck through). The normal render is not affected: the clean PDF still
# comes from `quarto render paper_traktok.qmd`.
#
#   Rscript render_diff.R                 # paper_traktok_old.qmd vs paper_traktok.qmd
#   Rscript render_diff.R old.qmd new.qmd # any two versions
#
# The old version is only rendered once: its .tex is kept and reused as long
# as it exists (delete paper_traktok_old.tex to force a re-render).
# latexdiff is taken from TinyTeX (installed on first use). If the diff .tex
# does not compile, it is kept as paper_traktok_diff.tex for manual fixes.

args <- commandArgs(trailingOnly = TRUE)
old <- if (length(args) >= 1) args[1] else "paper_traktok_old.qmd"
new <- if (length(args) >= 2) args[2] else "paper_traktok.qmd"
out <- "paper_traktok_diff"

old_tex <- sub("\\.qmd$", ".tex", basename(old))
new_tex <- sub("\\.qmd$", ".tex", basename(new))
diff_tex <- paste0(out, ".tex")

# latexdiff from TinyTeX (same TeX installation quarto uses)
bin_dir <- list.dirs(file.path(tinytex::tinytex_root(), "bin"), recursive = FALSE)[1]
latexdiff <- file.path(bin_dir, "latexdiff")
if (!file.exists(latexdiff)) tinytex::tlmgr_install("latexdiff")

# 1. render both versions to LaTeX (keep-tex is set in the YAML, enforced here)
render <- function(f) {
  quarto::quarto_render(f, output_format = "ccr-pdf", quiet = TRUE,
                        pandoc_args = c("-M", "keep-tex:true"))
}
if (file.exists(old_tex)) {
  message("using existing ", old_tex, " (delete it to re-render ", old, ")")
} else {
  message("rendering ", old)
  render(old)
}
message("rendering ", new)
render(new)
stopifnot(file.exists(old_tex), file.exists(new_tex))

# 2. latexdiff
# - Highlighting: pandoc's code block environment (fancyvrb); compared as a
#   whole, changed blocks are swapped (made visible in step 3)
# - abstract/keywords: CCR macros whose argument is text to be marked up
ld_opts <- c(
  "--allow-spaces",
  "--config", shQuote("VERBATIMENV=comment|Highlighting"),
  "--append-textcmd=abstract,keywords"
)
message("running latexdiff")
status <- system2(latexdiff, c(ld_opts, shQuote(old_tex), shQuote(new_tex)),
                  stdout = diff_tex, stderr = paste0(out, ".latexdiff.log"))
if (status != 0) stop("latexdiff failed, see ", out, ".latexdiff.log")

# 3. mark added / deleted code blocks
# latexdiff cannot mark up inside verbatim environments: a new block sits
# unmarked between \DIFaddbegin ... \DIFaddend, a deleted one is commented
# out (%DIFDELCMD < ...) between \DIFdelbegin ... \DIFdelend. Restore deleted
# blocks and give both a coloured bar on the left (blue = added, red = deleted).
added_opts   <- "frame=leftline,framerule=2pt,rulecolor=\\color{blue}"
deleted_opts <- "frame=leftline,framerule=2pt,rulecolor=\\color{red},formatcom=\\color{red}"
mark_code_blocks <- function(tex) {
  set_opts <- function(block, opts) {
    lines <- strsplit(block, "\n")[[1]]
    empty <- grepl("\\begin{Highlighting}[]", lines, fixed = TRUE)
    lines[empty] <- sub("\\begin{Highlighting}[]", paste0("\\begin{Highlighting}[", opts, "]"),
                        lines[empty], fixed = TRUE)
    more <- !empty & grepl("\\begin{Highlighting}[", lines, fixed = TRUE)
    lines[more] <- sub("\\begin{Highlighting}[", paste0("\\begin{Highlighting}[", opts, ","),
                       lines[more], fixed = TRUE)
    paste(lines, collapse = "\n")
  }
  # added blocks: just add the bar
  added <- gregexpr("(?s)\\\\DIFaddbegin .*?\\\\DIFaddend", tex, perl = TRUE)
  regmatches(tex, added) <- list(vapply(regmatches(tex, added)[[1]], function(r) {
    if (grepl("\\begin{Highlighting}", r, fixed = TRUE)) set_opts(r, added_opts) else r
  }, character(1)))
  # deleted blocks: uncomment if the commented-out commands are only the code
  # block (plus its Shaded box); otherwise leave latexdiff's output alone
  deleted <- gregexpr("(?s)\\\\DIFdelbegin .*?\\\\DIFdelend", tex, perl = TRUE)
  regmatches(tex, deleted) <- list(vapply(regmatches(tex, deleted)[[1]], function(r) {
    if (!grepl("%DIFDELCMD < \\begin{Highlighting}", r, fixed = TRUE)) return(r)
    lines <- strsplit(r, "\n")[[1]]
    cmd <- grepl("%DIFDELCMD < ", lines, fixed = TRUE)
    # the commented-out part of each line
    frag <- ifelse(cmd, gsub("%DIFDELCMD < ", "",
                             sub("^.*?%DIFDELCMD < ", "", lines, perl = TRUE), fixed = TRUE), "")
    inside <- cumsum(grepl("\\begin{Highlighting}", frag, fixed = TRUE)) >
      cumsum(grepl("\\end{Highlighting}", frag, fixed = TRUE)) |
      grepl("\\end{Highlighting}", frag, fixed = TRUE)
    other <- trimws(frag[cmd & !inside])
    if (!all(other %in% c("\\begin{Shaded}", "\\end{Shaded}", "%%%", ""))) {
      warning("deleted code block left unmarked (mixed region):\n", substr(r, 1, 300))
      return(r)
    }
    set_opts(paste(gsub("%DIFDELCMD < ", "", lines, fixed = TRUE), collapse = "\n"),
             deleted_opts)
  }, character(1)))
  tex
}
tex <- paste(readLines(diff_tex, warn = FALSE), collapse = "\n")
writeLines(mark_code_blocks(tex), diff_tex)

# 4. compile with xelatex (same engine as the paper)
message("compiling ", diff_tex)
tinytex::xelatex(diff_tex)
message("done: ", out, ".pdf")

# 5. clean up: keep the old .tex (and its _files, which it may reference)
unlink(c(sub("\\.qmd$", ".pdf", basename(old)), sub("\\.qmd$", ".pdf.md", basename(old)),
         paste0(out, ".latexdiff.log")))
