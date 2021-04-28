library(here)
library(rvest)
library(tidyverse)

source(here('data-get', 'fbref', 'utils.R'))

summaries = read_csv(here('data-get', 'fbref', 'processed', 'match-urls.csv'), col_types = cols(.default = 'c'))

# restricting to just this data
summaries = summaries %>% filter(szn >= '2014-2015')

twoleggedties = summaries %>%
  drop_na(stagecode) %>%
  arrange(szn, stagecode) %>%
  # filter out anything without complete data over two legs, except this current season
  filter((!is.na(url1) & !is.na(url2)) | (stage == 'knockout' & szn == CURRENT_SZN)) %>%
  # team 1 in the aggregate should always be the team that hosted leg 1
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
        if (is.na(.x) | is.na(.y)) {
          return ('')
        }
        str_c(
          as.numeric(str_split(.x, '–')[[1]][1]) + as.numeric(str_split(.y, '–')[[1]][2]),
          as.numeric(str_split(.x, '–')[[1]][2]) + as.numeric(str_split(.y, '–')[[1]][1]),
          sep = '–'
        )
      }
    ),
    # alpha sort of two team ids
    tieid = map2_chr(teamid1, teamid2, ~str_c(sort(c(.x, .y)), collapse = '|'))
  ) %>%
  select(
    szn, stagecode, tieid,
    competition, round, dates,
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
  select(szn, stagecode, tieid, teamid1, teamid2, score1, score2, url1, url2) %>%
  pivot_longer(-szn:-teamid2, names_to = 'col', values_to = 'val') %>%
  mutate(
    leg = str_sub(col, start = -1),
    col = str_replace_all(col, '1|2', '')
  ) %>%
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

# downloading

legshtml = legs %>%
  filter(!is.na(url)) %>%
  arrange(desc(szn), desc(stagecode)) %>%
  mutate(html = map(url, getorretrieve.games))

legshtml

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
