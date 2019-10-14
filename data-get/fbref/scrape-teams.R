library(here)
library(rvest)
library(tidyverse)

getorretrieve = function(url) {
  fname = url %>% 
    str_split('/') %>% 
    `[[`(1) %>% 
    `[`(length(.)) %>% 
    str_c('.html')
  
  fpath = here('data-get', 'fbref', 'teams', fname)
  
  # url = str_c('https://fbref.com/en/squads/', teamid, '/')
  
  if (file.exists(fpath)) {
    h = read_html(fpath)
  } else {
    h = read_html(url)
    write_html(h, fpath)
  }
  
  h
}

indexpage = tibble(url = 'https://fbref.com/en/squads')

countries = indexpage %>%
  mutate(
    rawhtml = map(url, getorretrieve),
    table = map(
      rawhtml,
      ~.x %>%
        html_node('table.stats_table') %>% 
        html_table()
    ),
    countryurl = map(
      rawhtml,
      ~.x %>% 
        html_nodes('th[data-stat="country"][scope="row"]') %>% 
        html_nodes('a') %>% 
        html_attr('href') %>% 
        str_c('https://fbref.com', .)
    )
  ) %>% 
  select(-url, -rawhtml) %>% 
  unnest(c(table, countryurl)) %>% 
  mutate(
    country = str_replace_all(Country, ' Football Clubs', ''),
    countrycode3 = str_sub(countryurl, start = 36, end = 38)
  ) %>% 
  select(country, countrycode2 = Flag, countrycode3, governingbody = `Governing Body`, countryurl)

countries

countrieshtml = countries %>%
  mutate(rawhtml = map(countryurl, getorretrieve))

clubs = countrieshtml %>% 
  mutate(
    table = map(
      rawhtml,
      ~.x %>% 
        html_node('table.stats_table') %>% 
        html_table() %>% 
        as_tibble() %>% 
        mutate_all(as.character)
    ),
    clubid = map(
      rawhtml,
      ~.x %>% 
        html_nodes('th[data-stat="squad"][scope="row"]') %>% 
        html_nodes('a') %>% 
        html_attr('href') %>% 
        str_sub(start = 12, end = 19)
    )
  ) %>% 
  select(-countryurl, -rawhtml) %>% 
  unnest(c(table, clubid))

clubs

clubs %>% write_csv(here('data-get', 'fbref', 'cleaned', 'fbref-teams.csv'), na = '')
