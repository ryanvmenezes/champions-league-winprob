library(here)
library(locfit)
library(tidyverse)

source(here('model', 'v1', 'utils.R'))

model = read_rds(here('model', this.version, 'model.rds'))
model

summary(model)

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
  # make predictions
  mutate(predictedprobt1 = predict(model, newdata = ., type = 'response'))

predmatrix

predmatrix %>% write_rds(here('model', this.version, 'predictions.rds'))
