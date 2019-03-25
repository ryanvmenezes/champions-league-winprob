Part 1: Getting results from goals
================

``` r
library(tidyverse)
```

    ## ── Attaching packages ───────────────────────────────────────────────────────────────────────────────── tidyverse 1.2.1 ──

    ## ✔ ggplot2 3.0.0     ✔ purrr   0.2.5
    ## ✔ tibble  1.4.2     ✔ dplyr   0.7.6
    ## ✔ tidyr   0.8.1     ✔ stringr 1.3.1
    ## ✔ readr   1.1.1     ✔ forcats 0.3.0

    ## ── Conflicts ──────────────────────────────────────────────────────────────────────────────────── tidyverse_conflicts() ──
    ## ✖ dplyr::filter() masks stats::filter()
    ## ✖ dplyr::lag()    masks stats::lag()

``` r
library(broom)
```

``` r
EQUIPOS = read_delim('raw/teamcrosswalk.psv', delim = '|')
```

    ## Parsed with column specification:
    ## cols(
    ##   fullteam = col_character(),
    ##   teamcode = col_character(),
    ##   country = col_character(),
    ##   shortcode = col_character()
    ## )

``` r
View(EQUIPOS)
```

``` r
GOLES = read_delim('raw/goles - liga de campeones - Sheet1.tsv', delim = '\t')
```

    ## Parsed with column specification:
    ## cols(
    ##   season = col_integer(),
    ##   round = col_character(),
    ##   tie = col_character(),
    ##   game = col_integer(),
    ##   minute = col_character(),
    ##   away = col_character(),
    ##   extra = col_character(),
    ##   shootout = col_character(),
    ##   note = col_character()
    ## )

``` r
goles = GOLES %>% 
  fill(season, round, tie, game) %>%
  separate(tie, c('t1','t2'), sep = '-', remove = FALSE) %>% 
  left_join(EQUIPOS %>% select(t1 = teamcode, t1full = fullteam), by = 't1') %>% 
  left_join(EQUIPOS %>% select(t2 = teamcode, t2full = fullteam), by = 't2')
```

``` r
head(goles)
```

    ## # A tibble: 6 x 13
    ##   season round tie   t1    t2     game minute away  extra shootout note 
    ##    <int> <chr> <chr> <chr> <chr> <int> <chr>  <chr> <chr> <chr>    <chr>
    ## 1   2017 first city… city  mona…     1 26     <NA>  <NA>  <NA>     <NA> 
    ## 2   2017 first city… city  mona…     1 32     a     <NA>  <NA>     <NA> 
    ## 3   2017 first city… city  mona…     1 40     a     <NA>  <NA>     <NA> 
    ## 4   2017 first city… city  mona…     1 58     <NA>  <NA>  <NA>     <NA> 
    ## 5   2017 first city… city  mona…     1 61     a     <NA>  <NA>     <NA> 
    ## 6   2017 first city… city  mona…     1 71     <NA>  <NA>  <NA>     <NA> 
    ## # ... with 2 more variables: t1full <chr>, t2full <chr>

``` r
tail(goles)
```

    ## # A tibble: 6 x 13
    ##   season round tie   t1    t2     game minute away  extra shootout note 
    ##    <int> <chr> <chr> <chr> <chr> <int> <chr>  <chr> <chr> <chr>    <chr>
    ## 1   2019 first ajax… ajax  madr…     2 72     a     <NA>  <NA>     <NA> 
    ## 2   2019 first live… live… baye…     1 <NA>   <NA>  <NA>  <NA>     <NA> 
    ## 3   2019 first live… live… baye…     2 39     <NA>  <NA>  <NA>     <NA> 
    ## 4   2019 first live… live… baye…     2 26     a     <NA>  <NA>     <NA> 
    ## 5   2019 first live… live… baye…     2 84     a     <NA>  <NA>     <NA> 
    ## 6   2019 first live… live… baye…     2 69     a     <NA>  <NA>     <NA> 
    ## # ... with 2 more variables: t1full <chr>, t2full <chr>

``` r
sum_goals = function(part) {
  # Gets the goals and away goals for a part of a game.
  # A "part" is regular or extra time.
  t1ag = part %>% filter(game == 2) %>% filter(!is.na(away)) %>% nrow()
  t2ag = part %>% filter(game == 1) %>% filter(!is.na(away)) %>% nrow()
  
  t1g = part %>% filter(game == 1) %>% filter(is.na(away)) %>% nrow() + t1ag
  t2g = part %>% filter(game == 2) %>% filter(is.na(away)) %>% nrow() + t2ag
  
  data.frame(t1g, t2g, t1ag, t2ag)
}
```

``` r
get_tie_result = function(goals) {
    winner = NULL
    pk = agr = aet = FALSE
    result = ""
    
    t1 = goals %>% select(t1) %>% distinct() %>% first()
    t2 = goals %>% select(t2) %>% distinct() %>% first()
    
    reg = goals %>%
      filter(minute != 'pk') %>%
      filter(is.na(extra)) %>% 
      filter(!is.na(minute))

    et = goals %>%
      filter(minute != 'pk') %>%
      filter(!is.na(extra)) %>% 
      filter(!is.na(minute))

    pkg = goals %>% filter(minute == 'pk')

    # goals and away goals in regulation
    reg_goals = sum_goals(reg)
    t1g = reg_goals$t1g
    t2g = reg_goals$t2g
    t1ag = reg_goals$t1ag
    t2ag = reg_goals$t2ag

    # goals and away goals in extra time
    et_goals = sum_goals(et)
    t1etg = et_goals$t1g
    t2etg = et_goals$t2g
    t1etag = et_goals$t1ag
    t2etag = et_goals$t2ag

    # pk shootout result
    t1pkwin = pkg %>%
      filter(away == 'a') %>%
      nrow() %>%
      as.logical()
    
    if ( (t1g+t1etg) != (t2g+t2etg) ) {
      # if goal sums differ, outright win
      winner = case_when(
        ((t1g+t1etg) > (t2g+t2etg)) ~ t1,
        TRUE ~ t2
      )
    } else if ( (t1ag+t1etag) != (t2ag+t2etag) ) {
      # if away goal sums differ, away goals win
      winner = case_when(
        ((t1ag+t1etag) > (t2ag+t2etag)) ~ t1,
        TRUE ~ t2
      )
      agr = TRUE
    } else {
      winner = case_when(
        t1pkwin ~ t1,
        TRUE ~ t2
      )
      pk = TRUE
    }

    # if goals in regulation are tied
    # and away goals in regulation are tied
    # this went to extra time
    if ((t1g == t2g) & (t1ag == t2ag)) {
        aet = TRUE
    }
    
    winnerfull = case_when(
      winner == t1 ~ goals %>% select(t1full) %>%  distinct() %>% first(),
      TRUE ~ goals %>% select(t2full) %>%  distinct() %>% first()
    )

    # a string summarizing the result
    result = str_c(
        goals %>% select(t1full) %>% distinct(), ' (',
        t1g+t1etg, '-',
        t2g+t2etg,
        case_when(aet ~ ' aet) ', TRUE ~ ') '),
        goals %>% select(t2full) %>% distinct(),
        case_when(
          pk ~ str_c(', ', winnerfull, ' won on penalties'),
          agr ~ str_c(', ', winnerfull, ' won on away goals'),
          TRUE ~ ''
        )
    )

    data.frame(winner=winner, pk=pk, agr=agr, aet=aet, result=result)
}
```

``` r
results = goles %>% 
  group_by(season, round, tie) %>% 
  do(get_tie_result(.))
```
