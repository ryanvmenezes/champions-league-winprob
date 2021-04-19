library(tidyverse)
library(yaml)
library(tidypredict)
library(glue)
library(furrr)

predictors = read_rds('model/v3/predictors/all.rds')

predictors

# use model to generate poisson mean for goals remaining in game

goal.predictions = predictors %>% 
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
  group_by(season, stagecode, tieid, minuteclean) %>%
  transmute(
    # season, stagecode, tieid,
    # minuteclean, 
    minuterown,
    goals,
    # pred.goals.left = fit,
    pred.goals.left = case_when(
      leg == 1 & minuteclean > 90 ~ 0,
      # leg == 2 & minuteclean == 180 & lead(minuteclean) != 181 ~ 0,
      leg == 2 & minuteclean == 180 & minuterown == max(minuterown) ~ 0,
      leg == 2 & minuteclean == 210 & minuterown == max(minuterown) ~ 0,
      TRUE ~ fit,
    ),
    leg = if_else(leg == 1, 'g1', 'g2'),
    team = case_when(
      leg == 'g1' & home == 1 ~ 't1',
      leg == 'g1' & home == 0 ~ 't2',
      leg == 'g2' & home == 1 ~ 't2',
      leg == 'g2' & home == 0 ~ 't1',
    ),
  ) %>% 
  ungroup() %>% 
  pivot_wider(
    names_from = team,
    values_from = c(goals, pred.goals.left),
    names_sep = '.'
  ) %>% 
  pivot_wider(
    names_from = leg,
    values_from = c(goals.t1, goals.t2, pred.goals.left.t1, pred.goals.left.t2),
    names_sep = '.'
  ) %>% 
  select(
    season, stagecode, tieid, minuteclean, minuterown,
    goals.t1.g1, goals.t2.g1, goals.t1.g2, goals.t2.g2,
    pred.goals.left.t1.g1, pred.goals.left.t2.g1, pred.goals.left.t1.g2, pred.goals.left.t2.g2
  ) %>% 
  arrange(season, stagecode, tieid, minuteclean, minuterown)

goal.predictions

# goal.predictions %>% filter(season == 2017, tieid == '206d90db|e2d8892c') %>% view() # barca-psg game with multiple extra time goals

generate.distributions = function(pred.df) {
  max.goals = 12
  
  pred.df %>%
    # four dist tables: one for each leg, one for each team in the leg
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
            mutate(prob = prob.t1.g1 * prob.t2.g1 * prob.t1.g2 * prob.t2.g2) %>% 
            as_tibble()
        }
      )
    ) %>% 
    ## unnest dist table and convert to win probability 
    select(minuteclean, minuterown, dist.table) %>%
    unnest(c(dist.table)) %>%
    mutate(
      t1 = t1.g1 + t1.g2,
      t2 = t2.g1 + t2.g2,
      t1.ag = t1.g2,
      t2.ag = t2.g1,
      winner = case_when(
        (t1 > t2) | (t1 == t2 & t1.ag > t2.ag) ~ 't1',
        (t2 > t1) | (t1 == t2 & t2.ag > t1.ag) ~ 't2',
        (t1 == t2) & (t1.ag == t2.ag) ~ 'pk'
      )
    ) %>%
    group_by(minuteclean, minuterown, winner) %>%
    summarise(prob = sum(prob)) %>%
    ungroup() %>%
    pivot_wider(names_from = winner, values_from = prob) %>%
    select(-t1, -t2, -pk, t1, t2, pk) %>%
    identity()
}

plan(multisession)

start = lubridate::now()

win.probabilities = goal.predictions %>%
  filter(season == 2017, tieid == '206d90db|e2d8892c') %>% 
  group_by(season, stagecode, tieid) %>%
  nest() %>%
  ungroup() %>%
  mutate(
    data = future_pmap(
      list(season, stagecode, tieid, data),
      function(season, stagecode, tieid, data) {
        fname = glue('model/v3/distributions/{season}_{stagecode}_{tieid}.rds')
        # if (file.exists(fname)) {
        #   return (read_rds(fname))
        # }
        dist = generate.distributions(data)
        dist %>% write_rds(fname, compress = 'gz')
        return (dist)
      },
      .progress = TRUE
    )
  )

end = lubridate::now()

beepr::beep()

win.probabilities %>%
  unnest(c(data)) %>%
  write_rds('model/v3/probabilities.rds', compress = 'gz')

print(end - start)