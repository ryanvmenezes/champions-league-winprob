library(here)
library(tidyverse)

summaries = read_csv(here('data-get', 'fbref', 'processed', 'match-urls.csv'), guess_max = 3000)

# the missing are any ties that did not have two legs broken down in detail in fbref

missing = summaries %>% 
  mutate(szn = as.numeric(str_sub(szn, end = 4)) + 1) %>% 
  rename(season = szn) %>% 
  filter(season >= 2015) %>% 
  drop_na(stagecode) %>% 
  filter(is.na(hometeam1) | is.na(hometeam2))

missing

missingformatted = missing %>% 
  mutate(
    tieid = map2_chr(teamid1, teamid2, ~str_c(sort(c(.x, .y)), collapse = '|')),
    winner = team1,
    winnerid = teamid1,
    agr = str_detect(str_to_lower(result), 'away goals'),
    aet = str_detect(str_to_lower(result), 'extra time'),
    pk = str_detect(str_to_lower(result), 'penalty')
  ) %>% 
  select(
    season, stagecode, tieid, team1, team2, winner,
    teamid1, teamid2, winnerid,
    aggscore, result, agr, aet, pk
  ) %>% 
  # exclude any that are sensibly missing 
  filter(
    !(
      (stagecode %in% c('cl-1k-6final', 'el-1k-9f')) |
        (season %in% c(2020, 2021))
    )
  )

missingformatted

missingformatted %>% write_csv(here('data-get', 'assemble', 'summary', 'missing-ties.csv'), na = '')
