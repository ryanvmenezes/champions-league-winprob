library(tidyverse)
library(yaml)
library(tidypredict)
library(glue)
library(here)

this.version = 'v3'

source(here('model', 'utils.R'))

leg1 = read_rds(here('model', this.version, 'files', 'leg1.rds'))

leg2 = read_rds(here('model', this.version, 'files', 'leg2.rds'))

leg1

leg2

leg1.preds = leg1 %>% 
  group_by(minuteclean) %>% 
  nest() %>% 
  mutate(
    model = map(
      minuteclean,
      ~glue('model/v3/files/minute-models/leg-1-minute-{.x}.yaml') %>% 
        read_yaml() %>% 
        as_parsed_model()
    ),
    predictions = map2(
      data,
      model,
      ~.x %>% 
        tidypredict_to_column(.y)
    )
  ) %>% 
  select(minuteclean, predictions) %>% 
  unnest(c(predictions)) %>% 
  ungroup() %>% 
  arrange(season, stagecode, tieid, home, minuterown)

leg2.preds = leg2 %>% 
  group_by(minuteclean) %>% 
  nest() %>% 
  mutate(
    model = map(
      minuteclean,
      ~glue('model/v3/files/minute-models/leg-2-minute-{.x}.yaml') %>% 
        read_yaml() %>% 
        as_parsed_model()
    ),
    predictions = map2(
      data,
      model,
      ~.x %>% 
        tidypredict_to_column(.y)
    )
  ) %>% 
  select(minuteclean, predictions) %>% 
  unnest(c(predictions)) %>% 
  ungroup() %>% 
  arrange(season, stagecode, tieid, home, minuterown)


leg2.preds


leg1.preds %>% 
  transmute(
    season, stagecode, tieid, minuteclean, minuterown,
    goals.left, pred.goals.left = fit,
    home = if_else(home == 1, 't1', 't2'),
  ) %>% 
  pivot_wider(
    names_from = home,
    values_from = c(goals.left, pred.goals.left),
    names_sep = '.'
  ) %>% 
  select(
    -goals.left.t1, -goals.left.t2, -pred.goals.left.t1, -pred.goals.left.t2,
    goals.left.t1, goals.left.t2, pred.goals.left.t1, pred.goals.left.t2
  ) %>% 
  mutate(
    dist.t1 = map(pred.goals.left.t1, ~dpois(0:20, .x)),
    dist.t2 = map(pred.goals.left.t2, ~dpois(0:20, .x))
  )
