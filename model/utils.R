source('utils.R')

summaries = read_rds(here('data', 'summary.rds'))
odds = read_rds(here('data', 'odds.rds'))
events = read_rds(here('data', 'events.rds'))

predmatrix = summaries %>% 
  # train model on everything but this most recent season
  filter(season < 2020) %>% 
  filter(has_events) %>% 
  filter(!has_invalid_match) %>% 
  left_join(events) %>% 
  left_join(odds) %>% 
  select(
    season, stagecode, tieid,
    t1win, minuteclean, minuterown,
    goalst1diff, awaygoalst1diff, redcardst1diff,
    probh1, probd1, proba1
  ) %>% 
  mutate(
    probh1 = replace_na(probh1, 0.33),
    probd1 = replace_na(probd1, 0.33),
    proba1 = replace_na(proba1, 0.33)
  )