library(here)
library(rvest)
library(tidyverse)

source(here('data-get', 'fbref', 'utils.R'))

leagues = tribble(
  ~competition, ~code_string, ~url,
  'Champions League','cl','https://fbref.com/en/comps/8/history/UEFA-Champions-League-Seasons',
  'Europa League','el','https://fbref.com/en/comps/19/history/UEFA-Europa-League-Seasons'
)

historyhtml = leagues %>% 
  mutate(html = map(url, read_html))

historyhtml

comps = historyhtml %>% 
  mutate(
    sznshtml = map(html, ~.x %>% html_nodes('[data-stat="season"] a')),
    szn = map(sznshtml, ~.x %>% html_text()),
    compurl = map(sznshtml, ~.x %>% html_attr('href') %>% str_c('https://fbref.com', .))
  ) %>% 
  select(-url, -html, -sznshtml) %>% 
  unnest(cols = c(szn, compurl))

comps

# comps = read_csv(here('data-get', 'fbref', 'competition-urls.csv'))
# 
# comps

compshtml = comps %>%
  mutate(
    html = map2(
      compurl,
      szn,
      function(.x, .y) {
        if (.y == CURRENT_SZN) return(getorretrieve.seasons(.x, override = TRUE))
        return(getorretrieve.seasons(.x))
      }
    )
  )

compshtml

qualszns = compshtml %>% 
  select(-compurl) %>%
  mutate(sznurl = map_chr(
    html,
    ~.x %>% 
      html_nodes('#inner_nav a') %>%
      html_attr('href') %>% 
      `[`(str_detect(., 'qual')) %>% 
      `[`(1) %>% 
      str_c('https://fbref.com', .)
  )) %>% 
  select(-html) %>% 
  drop_na(sznurl)

qualszns

qualsznshtml = qualszns %>% 
  mutate(
    html = map2(
      sznurl,
      szn,
      function(.x, .y) {
        if (.y == CURRENT_SZN) return(getorretrieve.seasons(.x, override = TRUE))
        return(getorretrieve.seasons(.x))
      }
    )
  ) %>% 
  mutate(stage = 'qualifying')

qualsznshtml

knockoutsznshtml = compshtml %>%
  rename(sznurl = compurl) %>% 
  mutate(stage = 'knockout')

knockoutsznshtml

allsznshtml = bind_rows(knockoutsznshtml, qualsznshtml) %>% 
  arrange(szn, competition)

allsznshtml %>% head()

allsznshtml %>% tail()

allsznshtml %>% 
  select(-html) %>% 
  write_csv(here('data-get', 'fbref', 'processed', 'season-urls.csv'))