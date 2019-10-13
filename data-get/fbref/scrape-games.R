library(here)
library(rvest)
library(tidyverse)

twolegs = read_csv(here('data-get', 'fbref', 'urls', 'two-leg-summary.csv'))

matches = bind_rows(
  twolegs %>% 
    select(competition:result, date = date1, score = score1, url = url1) %>% 
    mutate(leg = 1),
  twolegs %>% 
    select(competition:result, date = date2, score = score2, url = url2) %>% 
    mutate(leg = 2)
) %>% 
  select(-code_string, -dates, -winner, -aggscore, -result) %>% 
  drop_na(url) %>% 
  arrange(competition, szn, stage, round, team1)

matches %>% count(competition)

getorretrieve = function(url) {
  fname = url %>% 
    str_split('/') %>% 
    `[[`(1) %>% 
    `[`(length(.)) %>% 
    str_c('.html')
  
  fpath = here('data-get', 'fbref', 'games', fname)
  
  if (file.exists(fpath)) {
    h = read_html(fpath)
  } else {
    h = read_html(url)
    write_html(h, fpath)
  }
  
  pb$tick()$print()
  
  h
}

pb = progress_estimated(nrow(matches))
matcheshtml = matches %>%
  mutate(html = map(url, getorretrieve))
