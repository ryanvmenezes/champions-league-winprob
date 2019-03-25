``` r
library(tidyverse)
```

    ## ── Attaching packages ────────────────────────────────────────────────────────────────────────────────────────── tidyverse 1.2.1 ──

    ## ✔ ggplot2 3.0.0     ✔ purrr   0.2.5
    ## ✔ tibble  1.4.2     ✔ dplyr   0.7.6
    ## ✔ tidyr   0.8.1     ✔ stringr 1.3.1
    ## ✔ readr   1.1.1     ✔ forcats 0.3.0

    ## ── Conflicts ───────────────────────────────────────────────────────────────────────────────────────────── tidyverse_conflicts() ──
    ## ✖ dplyr::filter() masks stats::filter()
    ## ✖ dplyr::lag()    masks stats::lag()

``` r
winprob = read_csv('analysis/winprob-model.csv')
```

    ## Parsed with column specification:
    ## cols(
    ##   season = col_integer(),
    ##   round = col_character(),
    ##   tie = col_character(),
    ##   t1win = col_integer(),
    ##   made_minute = col_integer(),
    ##   away = col_character(),
    ##   t1goaldiff = col_integer(),
    ##   t1awaygoaldiff = col_integer(),
    ##   neutral = col_double(),
    ##   pregameodds = col_double()
    ## )

Most impactful goals
====================

``` r
winprob %>% 
  group_by(season, round, tie) %>% 
  mutate(wpdiff = abs(pregameodds - lag(pregameodds))) %>% 
  drop_na(away) %>% 
  arrange(-wpdiff) %>% 
  head(30) %>% 
  select(season, round, tie, made_minute, t1win, away, wpdiff)
```

    ## # A tibble: 30 x 7
    ## # Groups:   season, round, tie [28]
    ##    season round tie                made_minute t1win away  wpdiff
    ##     <int> <chr> <chr>                    <int> <int> <chr>  <dbl>
    ##  1   2009 semi  barcelona-chelsea          184     1 a      0.675
    ##  2   2012 first marseille-inter            184     1 a      0.636
    ##  3   2009 first arsenal-roma               217     1 a      0.618
    ##  4   2010 first bayern-fiorentina          153     1 a      0.590
    ##  5   2018 first juventus-tottenham         160     1 a      0.583
    ##  6   2019 first united-psg                 184     1 a      0.576
    ##  7   2017 qtr   bayern-madrid              151     0 a      0.575
    ##  8   2013 first madrid-united              159     1 a      0.574
    ##  9   2015 first psg-chelsea                209     0 a      0.573
    ## 10   2008 semi  liverpool-chelsea          157     0 a      0.557
    ## # ... with 20 more rows
