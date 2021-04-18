library(tidyverse)
library(yaml)
library(tidypredict)
library(glue)
library(here)

predictors = read_rds('model/v3/predictors/all.rds')

predictors

# use model to generate poisson mean for goals remaining in game

predictions = predictors %>% 
  group_by(leg, minuteclean) %>% 
  nest() %>% 
  mutate(
    model = map2(
      leg, minuteclean,
      ~glue('model/v3/models/leg-{.x}-minute-{.y}.yaml') %>% 
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
  select(leg, minuteclean, predictions) %>% 
  unnest(c(predictions)) %>% 
  ungroup() %>% 
  transmute(
    season, stagecode, tieid,
    minuteclean, minuterown,
    goals, goals.left,
    pred.goals.left = fit,
    pred.goals.left = case_when(
      leg == 1 & minuteclean > 90 ~ 0,
      leg == 2 & minuteclean == 180 & lead(minuteclean) != 181 ~ 0,
      leg == 2 & minuteclean == 210 ~ 0,
      TRUE ~ pred.goals.left,
    ),
    leg = if_else(leg == 1, 'g1', 'g2'),
    team = case_when(
      leg == 'g1' & home == 1 ~ 't1',
      leg == 'g1' & home == 0 ~ 't2',
      leg == 'g2' & home == 1 ~ 't2',
      leg == 'g2' & home == 0 ~ 't1',
    ),
  ) %>% 
  pivot_wider(
    names_from = team,
    values_from = c(goals, goals.left, pred.goals.left),
    names_sep = '.'
  ) %>% 
  pivot_wider(
    names_from = leg,
    values_from = c(goals.t1, goals.t2, goals.left.t1, goals.left.t2, pred.goals.left.t1, pred.goals.left.t2),
    names_sep = '.'
  ) 

predictions

max.goals = 12

prediction.calcs = predictions %>%
  # filter(row_number() > 350) %>% 
  # head(20) %>% 
  mutate(
    dist.t1.g1 = map2(
      pred.goals.left.t1.g1,
      goals.t1.g1,
      ~tibble(t1.g1 = 0:max.goals + .y, prob.t1.g1 = dpois(0:max.goals, .x)) %>%
        filter(t1.g1 <= max.goals) %>% 
        filter(prob.t1.g1 != 0)
    ),
    dist.t2.g1 = map2(
      pred.goals.left.t2.g1,
      goals.t2.g1,
      ~tibble(t2.g1 = 0:max.goals + .y, prob.t2.g1 = dpois(0:max.goals, .x)) %>%
        filter(t2.g1 <= max.goals) %>% 
        filter(prob.t2.g1 != 0)
    ),
    dist.t1.g2 = map2(
      pred.goals.left.t1.g2,
      goals.t1.g2,
      ~tibble(t1.g2 = 0:max.goals + .y, prob.t1.g2 = dpois(0:max.goals, .x)) %>%
        filter(t1.g2 <= max.goals) %>% 
        filter(prob.t1.g2 != 0)
    ),
    dist.t2.g2 = map2(
      pred.goals.left.t2.g2,
      goals.t2.g2,
      ~tibble(t2.g2 = 0:max.goals + .y, prob.t2.g2 = dpois(0:max.goals, .x)) %>%
        filter(t2.g2 <= max.goals) %>% 
        filter(prob.t2.g2 != 0)
    ),
    # dist.t1.g2 = map(pred.goals.left.t1.g2, ~tibble(t1.g2 = 0:15, prob.t1.g2 = dpois(0:15, .x))),
    # dist.t2.g2 = map(pred.goals.left.t2.g2, ~tibble(t2.g2 = 0:15, prob.t2.g2 = dpois(0:15, .x))),
    
    # # add "buffers" to beginning
    # dist.t1.g1 = map2(dist.t1.g1, goals.t1.g1, ~c(rep(0, .y), .x)),
    # dist.t2.g1 = map2(dist.t2.g1, goals.t2.g1, ~c(rep(0, .y), .x)),
    # dist.t1.g2 = map2(dist.t1.g2, goals.t1.g2, ~c(rep(0, .y), .x)),
    # dist.t2.g2 = map2(dist.t2.g2, goals.t2.g2, ~c(rep(0, .y), .x)),
    # 
    # # convert to tibble
    # dist.t1.g1 = map(dist.t1.g1, ~tibble(t1.g1 = 0:(length(.x) - 1), prob.t1.g1 = .x)),
    # dist.t2.g1 = map(dist.t2.g1, ~tibble(t2.g1 = 0:(length(.x) - 1), prob.t2.g1 = .x)),
    # dist.t1.g2 = map(dist.t1.g2, ~tibble(t1.g2 = 0:(length(.x) - 1), prob.t1.g2 = .x)),
    # dist.t2.g2 = map(dist.t2.g2, ~tibble(t2.g2 = 0:(length(.x) - 1), prob.t2.g2 = .x)),

  ) %>% 
  mutate(
    dist.table = pmap(
      list(dist.t1.g1, dist.t2.g1, dist.t1.g2, dist.t2.g2),
      ~{
        expand.grid(
          t1.g1 = ..1$t1.g1,
          t2.g1 = ..2$t2.g1,
          t1.g2 = ..3$t1.g2,
          t2.g2 = ..4$t2.g2
        ) %>% 
          left_join(..1, by = 't1.g1') %>% 
          left_join(..2, by = 't2.g1') %>% 
          left_join(..3, by = 't1.g2') %>% 
          left_join(..4, by = 't2.g2') %>% 
          as_tibble()
      }
    )
  ) %>% 
  select(season:minuterown, dist.table) %>% 
  unnest(c(dist.table)) %>% 
  mutate(
    t1 = t1.g1 + t1.g2,
    t2 = t2.g1 + t2.g2,
    t1.ag = t1.g2,
    t2.ag = t2.g1,
    prob = prob.t1.g1 * prob.t2.g1 * prob.t1.g2 * prob.t2.g2,
    winner = case_when(
      (t1 > t2) | (t1 == t2 & t1.ag > t2.ag) ~ 't1',
      (t2 > t1) | (t1 == t2 & t2.ag > t1.ag) ~ 't2',
      (t1 == t2) & (t1.ag == t2.ag) ~ 'pk'
    )
  ) %>% 
  group_by(season, stagecode, tieid, minuteclean, minuterown, winner) %>% 
  summarise(prob = sum(prob)) %>% 
  pivot_wider(names_from = winner, values_from = prob)
  
