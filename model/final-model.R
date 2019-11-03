library(here)
library(locfit)
library(tidyverse)

minmatrix = read_rds(here('data-get', 'assemble', 'minute-matrix.rds'))

minmatrix

minmatrixtrim = minmatrix %>%
  filter(season < 2020) %>% 
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

minmatrixtrim

model = locfit(
  t1win ~ minuteclean + goalst1diff + awaygoalst1diff + redcardst1diff + proba1 + probd1,
  data = minmatrixtrim,
  family = 'binomial'
)

model

summary(model)

model %>% write_rds(here('model', 'final-model.rds'))
