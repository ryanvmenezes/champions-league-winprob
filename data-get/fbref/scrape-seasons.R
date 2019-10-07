library(here)
library(rvest)
library(tidyverse)

leagues = tribble(
  ~competition, ~code_string, ~url,
  'Champions League','cl','https://fbref.com/en/comps/8/history/UEFA-Champions-League-Seasons',
  'Europa League','el','https://fbref.com/en/comps/19/history/UEFA-Europa-League-Seasons',
)

getorretrieve = function(url) {
  fname = url %>% 
    str_split('/') %>% 
    `[[`(1) %>% 
    `[`(length(.)) %>% 
    str_c('.html')
  
  fpath = here('data-get','fbref', 'raw', fname)
  
  if (file.exists(fpath)) {
    h = read_html(fpath)
  } else {
    h = read_html(url)
    write_html(h, fpath)
  }
  
  h
}

historyhtml = leagues %>% 
  mutate(html = map(url, getorretrieve)) 

historyhtml

szns = historyhtml %>% 
  mutate(sznshtml = map(html, ~.x %>% html_nodes('[data-stat="season"] a')),
         szn = map(sznshtml, ~.x %>% html_text()),
         source = map(sznshtml, ~.x %>% html_attr('href') %>% str_c('https://fbref.com', .)))

szns

sznshtml = szns %>% 
  select(-url, -html,-sznshtml) %>% 
  unnest() %>% 
  mutate(html = map(source, getorretrieve))

sznshtml

sznshtml %>% 
  mutate(qualurl = map_chr(
    html,
    ~.x %>% 
      html_nodes('#inner_nav a') %>%
      `[`(str_detect(., 'qual')) %>% 
      `[`(1)
  ))

sznshtml$html[[1]] %>%
  html_nodes('#inner_nav a') %>%
  html_attr('href') %>% 
  `[`(str_detect(., 'q'))
