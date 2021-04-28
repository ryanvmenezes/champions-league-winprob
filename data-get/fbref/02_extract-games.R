library(here)
library(rvest)
library(tidyverse)
library(furrr)

plan(multicore)
# beepr::beep()
options('future.fork.enable' = TRUE)
availableCores()

source(here('data-get', 'fbref', 'utils.R'))

allszns = read_csv(here('data-get', 'fbref', 'processed', 'season-urls.csv'))

allszns

allsznshtml = allszns %>%
  # filter(szn >= '2014-2015') %>%
  mutate(html = map(sznurl, getorretrieve.seasons))

allsznshtml

parsedgames = allsznshtml %>%
  # quicker eval with mutlticore, but won't work within rstudio
  mutate(games = future_map(html, extractgames, .progress = TRUE))
  # mutate(games = map(html, extractgames)) # line to run within rstudio, takes 40 seconds

parsedgames

## hand created file with codes for each round that alpha sort
stagecodes = read_csv(here('data-get', 'fbref', 'stage-code-crosswalk.csv'))

stagecodes

summaries = parsedgames %>%
  select(-html, -sznurl) %>%
  unnest(games) %>%
  separate(round, sep = ' \\(', into = c('round', 'dates')) %>%
  mutate(
    dates = str_replace_all(dates, '\\)', ''),
    roundu = str_to_upper(round),
  ) %>%
  left_join(
    stagecodes %>%
      mutate(
        roundu = str_to_upper(round)
      ) %>%
      select(-round)
  ) %>%
  select(stagecode, everything(), -roundu)

summaries

summaries %>%
  count(code_string, szn, competition, stage, round, stagecode)

summaries %>% count(stagecode)

summaries %>% write_csv(here('data-get', 'fbref', 'processed', 'match-urls.csv'), na = '')
