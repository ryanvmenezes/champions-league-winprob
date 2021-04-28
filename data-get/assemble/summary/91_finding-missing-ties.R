library(here)
library(tidyverse)

match.urls = read_csv(here('data-get', 'fbref', 'processed', 'match-urls.csv'), guess_max = 3000)

# the missing are any ties that did not have two legs broken down in detail in fbref

missing = match.urls %>% 
  mutate(szn = as.numeric(str_sub(szn, end = 4)) + 1) %>% 
  rename(season = szn) %>% 
  filter(season >= 2015) %>% # update this for new data
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
  # exclude any that are sensibly missing 
  filter(!(stagecode %in% c('cl-1k-6final', 'el-1k-9final'))) %>% 
  filter(!(season == 2020 & stage == 'knockout')) %>% 
  filter(!(season == 2021 & stage == 'qualifying')) %>% 
  separate(aggscore, sep = '–', into = c('aggscore1', 'aggscore2'), remove = FALSE) %>% 
  mutate(t1win = aggscore1 > aggscore2) %>% 
  select(
    season, stagecode, tieid,
    competition, round, dates,
    team1, team2, winner,
    teamid1, teamid2, winnerid,
    aggscore, aggscore1, aggscore2, 
    result, t1win, agr, aet, pk
  )

missingformatted

missingformatted %>% write_csv(here('data-get', 'assemble', 'summary', 'missing-ties.csv'), na = '')
