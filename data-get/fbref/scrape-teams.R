library(here)
library(rvest)
library(tidyverse)

summaries = read_csv(here('data-get', 'fbref', 'cleaned', 'two-legged-ties.csv'))

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
teamhtml

teamhtml$html[[1]] %>% 
  html_node('div#meta') %>% 
  html_nodes('a') %>% 
  `[`(str_detect(., '/country/')) %>% 
  `[`(1) %>% 
  html_text()

teamhtml$html[[2]] %>% 
  html_nodes('link[rel="canonical"]') %>% 
  html_attr('href') %>% 
  str_split('/') %>% 
  `[[`(1) %>% 
  `[`(length(.)) %>% 
  str_replace_all('-Stats', '') %>% 
  str_replace_all('-', ' ')


tmp = teamhtml %>% 
  mutate(
    fullteamname = map_chr(
      html,
      function(.x) {
        res = .x %>% 
          html_nodes('title') %>% 
          html_text() %>% 
          str_replace(' Stats \\| FBref.com', '') %>% 
          str_replace(' Stats and History \\| FBref.com', '') %>% 
          str_replace('2018-2019 ', '')
        if (res == '') {
          res = .x %>% 
            html_nodes('link[rel="canonical"]') %>% 
            html_attr('href') %>% 
            str_split('/') %>% 
            `[[`(1) %>% 
            `[`(length(.)) %>% 
            str_replace_all('-Stats', '') %>% 
            str_replace_all('-', ' ')
        }
        res
      }
    ),
    country = map_chr(
      html,
      function(.x) {
        res = .x %>%
          html_node('div#meta') %>% 
          html_nodes('a') %>% 
          `[`(str_detect(., '/country/')) %>% 
          `[`(1) %>% 
          html_text()
        if (length(res) == 0) { return (NA_character_) }
        res
      }
    )
  ) %>% 
  select(-html)

tmp

