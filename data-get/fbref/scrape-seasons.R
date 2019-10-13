library(here)
library(rvest)
library(tidyverse)

leagues = tribble(
  ~competition, ~code_string, ~url,
  'Champions League','cl','https://fbref.com/en/comps/8/history/UEFA-Champions-League-Seasons',
  'Europa League','el','https://fbref.com/en/comps/19/history/UEFA-Europa-League-Seasons'
)

# todo: add szn and override = FALSE as args
# CURRENT_SZN = '2019-20'

getorretrieve = function(url) {
  fname = url %>% 
    str_split('/') %>% 
    `[[`(1) %>% 
    `[`(length(.)) %>% 
    str_c('.html')
  
  fpath = here('data-get', 'fbref', 'seasons', fname)
  
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
  mutate(
    sznshtml = map(html, ~.x %>% html_nodes('[data-stat="season"] a')),
    szn = map(sznshtml, ~.x %>% html_text()),
    sznurl = map(sznshtml, ~.x %>% html_attr('href') %>% str_c('https://fbref.com', .))
  ) %>% 
  select(-url, -html, -sznshtml) %>% 
  unnest(cols = c(szn, sznurl))

szns

szns %>% write_csv(here('data-get', 'fbref', 'urls', 'season-urls.csv'))

sznshtml = szns %>% 
  mutate(html = map(sznurl, getorretrieve))

sznshtml

qualszns = sznshtml %>% 
  select(-sznurl) %>% 
  mutate(sznurl = map_chr(
    html,
    ~.x %>% 
      html_nodes('#inner_nav a') %>%
      html_attr('href') %>% 
      `[`(str_detect(., 'qual')) %>% 
      `[`(1) %>% 
      str_c('https://fbref.com', .)
  )) %>% 
  select(-html)

qualszns

qualszns %>% write_csv(here('data-get', 'fbref', 'urls', 'qual-season-urls.csv'))

qualsznshtml = qualszns %>% 
  mutate(html = map(sznurl, getorretrieve))

qualsznshtml

extractgames = function(h) {
  round = h %>%
    html_nodes('#content > h3') %>% 
    html_text() %>% 
    str_trim()
  
  games = h %>% 
    html_nodes('#content > h3 + div.matchup') %>% 
    map(~html_children(.x))
  
  df = tibble(round, games) %>%
    mutate(
      team1 = map(
        games,
        ~.x %>% 
          html_node('.match-summary .team1') %>% 
          html_text() %>% 
          str_squish()
      ),
      team2 = map(
        games,
        ~.x %>% 
          html_node('.match-summary .team2') %>% 
          html_text() %>% 
          str_squish()
      ),
      winner = map(
        games,
        ~.x %>% 
          html_node('.match-summary .winner') %>% 
          html_text() %>% 
          str_squish()
      ),
      aggscore = map(
        games,
        ~.x %>% 
          html_node('.match-summary .match-detail') %>% 
          html_text() %>% 
          str_squish()
      ),
      result = map(
        games,
        ~.x %>% 
          html_node('.matchup-note') %>% 
          html_text() %>% 
          str_squish()
      ),
      date1 = map(
        games,
        ~.x %>%
          html_node('.matches > div:nth-child(1)') %>%
          html_node('.match-date small') %>%
          html_text()
      ),
      score1 = map(
        games,
        ~.x %>%
          html_node('.matches > div:nth-child(1)') %>%
          html_node('.match-detail .match-score') %>%
          html_text() %>%
          str_squish()
      ),
      url1 = map(
        games,
        ~.x %>%
          html_node('.matches > div:nth-child(1)') %>%
          html_node('.match-detail .match-score > small > a') %>%
          html_attr('href') %>%
          str_squish() %>%
          str_c('https://fbref.com', .)
      ),
      date2 = map(
        games,
        ~.x %>%
          html_node('.matches > div:nth-child(2)') %>%
          html_node('.match-date small') %>%
          html_text()
      ),
      score2 = map(
        games,
        ~.x %>%
          html_node('.matches > div:nth-child(2)') %>%
          html_node('.match-detail .match-score') %>%
          html_text() %>%
          str_squish()
      ),
      url2 = map(
        games,
        ~.x %>%
          html_node('.matches > div:nth-child(2)') %>%
          html_node('.match-detail .match-score > small > a') %>%
          html_attr('href') %>%
          str_squish() %>%
          str_c('https://fbref.com', .)
      )
    ) %>% 
    select(-games) %>%
    unnest(
      c(
        team1, team2, winner, aggscore, result,
        date1, score1, url1,
        date2, score2, url2
      ),
      keep_empty = TRUE
    )
  
  df
}

parsedgames = bind_rows(
  sznshtml %>% 
    mutate(stage = 'knockout') %>% 
    select(-sznurl),
  qualsznshtml %>% 
    mutate(stage = 'qualifying') %>% 
    select(-sznurl)
  ) %>% 
  mutate(games = map(html, extractgames))

parsedgames

twolegsummary = parsedgames %>% 
  select(-html) %>% 
  unnest(games) %>%
  separate(round, sep = ' \\(', into = c('round', 'dates')) %>% 
  mutate(dates = str_replace_all(dates, '\\)', ''))

twolegsummary

twolegsummary %>% count(round)

twolegsummary %>%
  write_csv(here('data-get', 'fbref', 'urls', 'two-leg-summary.csv'), na = '')

