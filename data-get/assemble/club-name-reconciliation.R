library(here)
library(rvest)
library(tidyverse)

summaries = read_csv(here('data-get', 'fbref', 'processed', 'two-legged-ties.csv'))

distinctteams = summaries %>% 
  select(starts_with('team')) %>% 
  pivot_longer(starts_with('team')) %>% 
  mutate(name = str_sub(name, end = -2)) %>% 
  pivot_wider(names_from = name, values_from = value) %>%
  unnest(c(team, teamid)) %>% 
  distinct() %>%
  select(club = team, clubid = teamid) %>% 
  group_by(clubid) %>% 
  nest() %>% 
  mutate(clubshortnames = map_chr(data, ~str_c(.x$club, collapse = '|'))) %>% 
  select(-data)

distinctteams

fbrefteams = read_csv(here('data-get', 'fbref', 'processed', 'fbref-all-teams.csv'))
fbrefteams

europeteamsfbref = fbrefteams %>% 
  select(club = Squad, clubid, country, countrycode = countrycode3, governingbody) %>% 
  # manually add this missing team
  bind_rows(
    tibble(club = 'Juventus', clubid = 'e0652b02', country = 'Italy', countrycode = 'ITA', governingbody = 'UEFA')
  ) %>% 
  right_join(distinctteams, by = 'clubid') %>% 
  arrange(club)

europeteamsfbref

europeteamsfbref %>% write_csv(here('data-get', 'assemble', 'europe-teams-fbref.csv'), na = '')

odds = read_csv(here('data-get', 'oddsportal', 'processed', 'odds.csv'), na = '-')
odds

europeteamsodds = odds %>% 
  # filter(season > 2015) %>% 
  # filter(round != 'Group Stage') %>% 
  select(teamh, teama) %>% 
  pivot_longer(starts_with('team')) %>% 
  mutate(name = str_sub(name, end = -2)) %>% 
  pivot_wider(names_from = name, values_from = value) %>% 
  unnest(team) %>% 
  distinct() %>% 
  arrange(team)

europeteamsodds

europeteamsodds %>% write_csv(here('data-get', 'assemble', 'europe-teams-odds.csv'), na = '')

europeteamsodds %>% mutate(team = gsub(' \\(.*', '', team)) %>% distinct()
