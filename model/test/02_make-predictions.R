library(here)
library(locfit)
library(tidyverse)

summaries = read_rds(here('data', 'summary.rds'))
odds = read_rds(here('data', 'odds.rds'))
events = read_rds(here('data', 'events.rds'))

summaries
odds
events

final.models = read_rds(here('model', 'v2', 'models.rds'))
final.models

predictions = final.models %>% 
  mutate(predictions = map2(
    interval.data,
    model,
    ~.x %>% 
      mutate(predictedprobt1 = predict(.y, newdata = ., type = 'response'))
  )) %>% 
  select(predictions) %>% 
  unnest(c(predictions))

predictions

predmatrix = summaries %>%
  filter(has_events) %>% 
  filter(!has_invalid_match) %>% 
  left_join(events) %>% 
  left_join(odds) %>% 
  select(
    season, stagecode, tieid,
    t1win,
    probh1, probd1, proba1,
    minuteclean, minuterown,
    goalst1diff, awaygoalst1diff, redcardst1diff,
    player, playerid, eventtype
  ) %>% 
  mutate(
    probh1 = replace_na(probh1, 0.33),
    probd1 = replace_na(probd1, 0.33),
    proba1 = replace_na(proba1, 0.33)
  ) %>% 
  # join to predictions
  right_join(predictions %>% select(season, stagecode, tieid, t1win, minuteclean, minuterown, predictedprobt1))

predmatrix

predmatrix %>% write_rds(here('model', 'v2', 'predictions.rds'))
