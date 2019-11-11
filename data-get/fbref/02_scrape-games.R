library(here)
library(rvest)
library(tidyverse)

summaries = read_csv(here('data-get', 'fbref', 'processed', 'match-urls.csv'))
summaries

# team 1 in the aggregate should always be the team that hosted leg 1
twoleggedties = summaries %>%
  drop_na(stagecode) %>% 
  arrange(szn, stagecode) %>% 
  # filter out anything without complete data over two legs
  filter(!is.na(url1) & !is.na(url2)) %>%
  mutate(
    hometeamid1 = case_when(
      hometeam1 == team1 ~ teamid1,
      hometeam1 == team2 ~ teamid2,
      TRUE ~ NA_character_
    ),
    hometeamid2 = case_when(
      hometeam2 == team1 ~ teamid1,
      hometeam2 == team2 ~ teamid2,
      TRUE ~ NA_character_
    ),
    winnerid = case_when(
      winner == team1 ~ teamid1,
      winner == team2 ~ teamid2,
      TRUE ~ NA_character_
    ),
    team1 = hometeam1,
    team2 = hometeam2,
    teamid1 = hometeamid1,
    teamid2 = hometeamid2
  ) %>% 
  mutate(
    aggscore = map2_chr(
      score1,
      score2,
      function(.x, .y) {
        str_c(
          as.numeric(str_split(.x, '–')[[1]][1]) + as.numeric(str_split(.y, '–')[[1]][2]),
          as.numeric(str_split(.x, '–')[[1]][2]) + as.numeric(str_split(.y, '–')[[1]][1]),
          sep = '–'
        )
      }
    ),
    tieid = map2_chr(teamid1, teamid2, ~str_c(sort(c(.x, .y)), collapse = '|'))
  ) %>% 
  select(
    szn, stagecode, tieid,
    team1, team2, winner,
    teamid1, teamid2, winnerid,
    aggscore, result,
    score1, score2,
    url1, url2
  )

twoleggedties

twoleggedties %>% 
  select(-url1, -url2) %>% 
  write_csv(here('data-get', 'fbref', 'processed', 'two-legged-ties.csv'), na = '')

legs = twoleggedties %>% 
  select(-team1, -team2, -winner, -winnerid, -aggscore, -result) %>% 
  pivot_longer(-szn:-teamid2, names_to = 'col', values_to = 'val') %>% 
  mutate(leg = str_sub(col, start = -1),
         col = str_replace_all(col, '1|2', '')) %>% 
  pivot_wider(names_from = col, values_from = val) %>% 
  arrange(szn, stagecode, teamid1, leg)

legs

legs %>% count(stagecode)

countbyseason = legs %>%
  mutate(comp = str_sub(stagecode, end = 2)) %>%
  count(comp, szn)

countbyseason

countbyseason %>%
  write_csv(here('data-get', 'fbref', 'processed', 'count-leg-data-by-season.csv'))

getorretrieve = function(url) {
  fname = url %>% 
    str_split('/') %>% 
    `[[`(1) %>% 
    `[`(length(.)) %>% 
    str_c('.html')
  
  fpath = here('data-get', 'fbref', 'raw', 'games', fname)
  
  if (file.exists(fpath)) {
    h = read_html(fpath)
  } else {
    h = read_html(url)
    write_html(h, fpath)
  }
  
  pb$tick()$print()
  
  h
}

pb = progress_estimated(nrow(legs))
legshtml = legs %>%
  mutate(html = map(url, getorretrieve))

legshtml

parseevents = function(tm) {
  player = tm %>%
    html_node('a') %>%
    html_text()
  
  playerid = tm %>%
    html_node('a') %>%
    html_attr('href') %>%
    str_replace('/en/players/','') %>%
    str_sub(end = 8)
  
  eventtype = tm %>%
    html_node('div') %>%
    html_attr('class') %>%
    str_replace('event_icon ', '')
  
  minute = tm %>%
    html_text() %>%
    str_trim() %>%
    str_replace('&rsquor;', '') %>%
    str_split(' · ') %>%
    map_chr(`[`, 2)
  
  tibble(player, playerid, eventtype, minute)
}

getevents = function(h) {
  aevents = h %>% 
    html_node('div#a.event') %>% 
    html_children() %>% 
    parseevents() %>% 
    mutate(team = 1)
  
  bevents = h %>% 
    html_node('div#b.event') %>% 
    html_children() %>% 
    parseevents() %>% 
    mutate(team = 2)
  
  pb$tick()$print()
  
  bind_rows(aevents, bevents)
}

pb = progress_estimated(nrow(legs))
parsedevents = legshtml %>% 
  mutate(events = map(html, getevents)) %>% 
  select(-url, -html) %>% 
  unnest(events)

parsedevents

## checking the data
# parsedevents %>% count(eventtype)
# parsedevents %>% pull(minute) %>% str_replace_all('\\+\\d+', '') %>% unique() %>% as.integer() %>% sort()

parsedevents %>%
  write_csv(here('data-get', 'fbref', 'processed', 'match-events.csv'))
