library(here)
library(rvest)
library(tidyverse)

summaries = read_csv(here('data-get', 'fbref', 'cleaned', 'two-legged-ties-all.csv'))

distinctteams = summaries %>% 
  select(starts_with('team')) %>% 
  pivot_longer(starts_with('team')) %>% 
  mutate(name = str_sub(name, end = -2)) %>% 
  pivot_wider(names_from = name, values_from = value) %>%
  unnest(c(team, teamid)) %>% 
  distinct() %>%
  group_by(teamid) %>% 
  nest() %>% 
  mutate(teamnames = map_chr(data, ~str_c(.x$team, collapse = '|'))) %>% 
  select(-data)

distinctteams

distinctteams %>% filter(str_detect(teamnames, '\\|')) %>% View()

getorretrieve = function(teamid) {
  fname = str_c(teamid, '.html')
  
  fpath = here('data-get', 'fbref', 'teams', fname)
  
  url = str_c('https://fbref.com/en/squads/', teamid, '/')
  
  if (file.exists(fpath)) {
    h = read_html(fpath)
  } else {
    h = read_html(url)
    write_html(h, fpath)
  }
  
  pb$tick()$print()
  
  h
}

pb = progress_estimated(nrow(distinctteams))
teamhtml = distinctteams %>% 
  mutate(html = map(teamid, getorretrieve))
