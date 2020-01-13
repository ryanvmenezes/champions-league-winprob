library(here)
library(locfit)
library(tidyverse)

summaries = read_rds(here('data', 'summary.rds'))
odds = read_rds(here('data', 'odds.rds'))
events = read_rds(here('data', 'events.rds'))

summaries
odds
events

predmatrix = summaries %>% 
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

predmatrix

# version 1 ---------------------------------------------------------------

# model = locfit(
#   t1win ~ minuteclean + goalst1diff + awaygoalst1diff + redcardst1diff + probh1 + proba1,
#   data = predmatrix,
#   family = 'binomial'
# )
# 
# model
# 
# summary(model)
# 
# model %>% write_rds(here('model', 'models', 'v1.rds'))


# version 2 ---------------------------------------------------------------

## 90 minutes of game 1
## 90 minutes of game 2
## 30 minutes of extra time

## half 1, half 2, half 3, half 4, ET


