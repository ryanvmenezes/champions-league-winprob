library(here)
library(tidyverse)

odds = read_csv(here('data-get', 'oddsportal', 'processed', 'odds.csv'), na = '-')

odds

namesjoined = read_csv(here('data-get', 'assemble', 'joining-progress.csv'))

namesjoined

summaries = read_csv(here('data-get', 'fbref', 'processed', 'two-legged-ties.csv'))

summaries

oddsjoined = odds %>% 
  filter(season >= 2015) %>%
  filter(round != 'Group Stage') %>%
  left_join(namesjoined %>% select(teamh = team, teamidh = fbrefid)) %>% 
  left_join(namesjoined %>% select(teama = team, teamida = fbrefid)) %>% 
  mutate(tieid = map2_chr(teamidh, teamida, ~str_c(sort(c(.x, .y)), collapse = '|')))

oddsjoined = oddsjoined %>% 
  anti_join(
    oddsjoined %>% 
      count(season, tieid) %>% 
      filter(n != 2)
  ) %>% 
  group_by(season, tieid) %>% 
  mutate(tieorder = rank(date)) %>% 
  ungroup() %>% 
  select(comp, season, tieid, round, tieorder, date, everything()) %>% 
  select(-page)

oddsjoined

oddsjoined %>% 
  write_csv(here('data-get', 'assemble', 'odds-joined.csv'), na = '')
