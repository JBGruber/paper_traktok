# `traktok` — Making TikTok Data Accessible for Research <img src="media/logo.png" align="right" height="138" alt="traktok logo" />

This repository holds the source files of the paper:

> Gruber, J. B. (forthcoming). traktok — Making TikTok data accessible for research. *Computational Communication Research*.

The paper has been accepted for publication in [*Computational Communication Research*](https://www.aup-online.com/content/journals/26659085).
A preprint is available on [SocArXiv](https://doi.org/10.31235/osf.io/xrgc6_v2).
The `R` package itself lives at <https://github.com/JBGruber/traktok>.

## Abstract

The social media platform TikTok has surged in societal and political significance, underscoring the need for communication researchers to study its content and dynamics.
`traktok` is an `R` package that combines an implementation of the TikTok Research API with access to TikTok content through web-scraping.
While it is neither the first nor only tool to do so, the combination of both ways to retrieve data from the platform with an easy-to-understand consistent syntax is built to encourage TikTok research.
The package enables searching for videos, retrieving user information, downloading video and image files, and collecting comments and follower networks.
Importantly, both access methods can be combined, for example by using the Research API to identify relevant content and web-scraping to download the actual video files, enabling comprehensive data collection.
An empirical comparison of both data access methods reveals significant discrepancies in data completeness, with both APIs returning different subsets of content, highlighting the importance of methodological transparency in TikTok research.
The package has already been employed in several published studies across communication research and other disciplines, demonstrating its utility for systematic investigation of the platform.

## How to render

The paper is written in [Quarto](https://quarto.org/) and uses the [CCR template](https://github.com/ccr-journal/ccr-quarto), which is included in `_extensions/`.

1. Install [R](https://www.r-project.org/) and [Quarto](https://quarto.org/docs/get-started/)
2. Render:

```r
quarto::quarto_render("paper_traktok.qmd")
```

Or install [Quarto](https://quarto.org/docs/get-started/) on the command line and run

```bash
quarto render paper_traktok.qmd
```

## How to cite

Gruber, J. B. (forthcoming). traktok — Making TikTok data accessible for research. *Computational Communication Research*.

```bib
@article{gruber_traktok_forthcoming,
  title    = {{traktok} --- {Making} {TikTok} Data Accessible for Research},
  author   = {Gruber, Johannes B.},
  journal  = {Computational Communication Research},
  issn     = {2665-9085},
  year     = {forthcoming},
  pubstate = {forthcoming},
  language = {en},
}
```

Until the article is published, you can also cite the preprint:

Gruber, J. B. (2025). traktok — Making TikTok data accessible for research. *SocArXiv*. https://doi.org/10.31235/osf.io/xrgc6_v2

```bib
@article{gruber_traktok_2025,
  title   = {{traktok} --- {Making} {TikTok} Data Accessible for Research},
  author  = {Gruber, Johannes B.},
  journal = {SocArXiv},
  year    = {2025},
  month   = jun,
  doi     = {10.31235/osf.io/xrgc6_v2},
  url     = {https://osf.io/xrgc6_v2},
}
```
