library(here)
library(tidyverse)

ties = read_csv(here('data-get', 'fbref', 'processed', 'two-legged-ties.csv'))

ties

extra.aet.ties = read_csv(here('data-get', 'assemble', 'summary', 'extra-aet-ties.csv'))

extra.aet.ties

results = ties %>% 
  mutate(szn = as.numeric(str_sub(szn, end = 4)) + 1) %>% 
  rename(season = szn) %>% 
  separate(aggscore, into = c('aggscore1','aggscore2'), remove = FALSE) %>% 
  left_join(
    extra.aet.ties %>% 
      select(season, stagecode, tieid) %>% 
      mutate(extra.aet = TRUE)
  ) %>% 
  replace_na(list(extra.aet = FALSE)) %>% 
  mutate(
    t1win = (winner == team1),
    agr = str_detect(str_to_lower(result), 'away goals'),
    aet = str_detect(str_to_lower(result), 'extra time'),
    aet = case_when(
      extra.aet ~ TRUE,
      TRUE ~ aet
    ),
    pk = str_detect(str_to_lower(result), 'penalty')
  ) %>% 
  select(-extra.aet) %>% 
  mutate(
    # fix an error in the data
    agr = case_when(
      (aggscore1 == aggscore2) & (!pk) ~ TRUE,
      TRUE ~ agr
    ),
    # new result string format
    result = str_c(
      team1,
      ' (',
      aggscore,
      if_else(aet, ' aet', ''),
      ') ',
      team2,
      if_else(agr, str_c(', ', winner, ' won on away goals'), ''),
      if_else(pk, str_c(', ', winner, ' won on penalty kicks'), '')
    )
  )

results

# integrity checks
results %>% filter(score1 == score2) %>% filter(!pk) %>% nrow()
results %>% filter(score1 == score2) %>% filter(!aet) %>% nrow()
results %>% filter(aggscore1 == aggscore2) %>% filter(!pk) %>% filter(!agr) %>% nrow()
results %>% filter(as.numeric(aggscore1) > as.numeric(aggscore2)) %>% filter(winnerid != teamid1) %>% nrow()
results %>% filter(as.numeric(aggscore2) > as.numeric(aggscore1)) %>% filter(winnerid != teamid2) %>% nrow()


# helper tables

oddsbytie = read_csv(here('data-get', 'assemble', 'odds', 'odds.csv'))

oddsbytie

hasodds = oddsbytie %>%
  select(season, stagecode, tieid) %>% 
  mutate(has_odds = TRUE)

hasodds

missing = read_csv(here('data-get', 'assemble', 'summary', 'missing-ties.csv'))

missing

noevents = missing %>% 
  mutate(has_events = FALSE)

noevents

invalid = read_csv(here('data-get', 'assemble', 'summary', 'invalid-ties.csv'))

invalid

hasinvalidmatch = invalid %>% 
  select(season, stagecode, tieid) %>% 
  mutate(has_invalid_match = TRUE)

hasinvalidmatch

# create final table
assemblingsummary = results %>% 
  bind_rows(noevents) %>% 
  left_join(hasodds) %>% 
  left_join(hasinvalidmatch) %>% 
  mutate(
    has_events = replace_na(has_events, TRUE),
    has_odds = replace_na(has_odds, FALSE),
    has_invalid_match = replace_na(has_invalid_match, FALSE),
    in_progress = is.na(winner)
  ) %>% 
  arrange(season, stagecode, tieid)

assemblingsummary

# write out final table
assemblingsummary %>% write_csv(here('data-get', 'assemble', 'summary', 'summary.csv'), na = '')
assemblingsummary %>% write_rds(here('data', 'summary.rds'))
