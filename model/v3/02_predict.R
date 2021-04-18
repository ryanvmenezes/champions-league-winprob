library(tidyverse)
library(yaml)
library(tidypredict)
library(glue)
library(here)
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
    # model.coef = map2(
    #   leg, minuteclean,
    #   ~read_csv(
    #     glue('model/v3/models/leg-{.x}-minute-{.y}.csv'),
    #     col_types = cols(
    #       term = col_character(),
    #       estimate = col_double(),
    #       std.error = col_double(),
    #       statistic = col_double(),
    #       p.value = col_double()
    #     )
    #   )
    # ),
    # predictions = map2(
    #   data,
    #   model.coef,
    #   # convert tidy coefficient table to prediction
    #   function(data, coef.table) {
    #     all.predictors = c('(Intercept)', 'prob.diff', 'goals.edge', 'away.goals.edge', 'players.edge', 'home')
    #     
    #     coef.wide = coef.table %>% 
    #       select(term, estimate) %>% 
    #       right_join(tibble(term = all.predictors), by = 'term') %>% 
    #       mutate(estimate = replace_na(estimate, 0)) %>% 
    #       pivot_wider(names_from = term, values_from = estimate) %>% 
    #       mutate(joinkey = 1)
    #     
    #     joined = data %>% 
    #       mutate(joinkey = 1) %>% 
    #       left_join(coef.wide, by = 'joinkey', suffix = c('', '.coef')) %>% 
    #       mutate(
    #         fit = exp(
    #           `(Intercept)` +
    #             prob.diff * prob.diff.coef +
    #             goals.edge + goals.edge.coef +
    #             away.goals.edge + away.goals.edge.coef +
    #             players.edge + players.edge.coef +
    #             home * home.coef
    #         )
    #       ) %>% 
    #       select(-joinkey, -`(Intercept)`, -ends_with('coef'))
    #     
    #     return (joined)
    #   }
    # )
  ) %>% 
  select(leg, minuteclean, predictions) %>% 
  unnest(c(predictions)) %>% 
  ungroup() %>% 
  transmute(
    season, stagecode, tieid,
    minuteclean, minuterown,
    goals,
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

generate.distributions = function(pred.df) {
  max.goals = 12
  
  pred.df %>%
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

# plan(multisession)
# 
# start = lubridate::now()

win.probabilities = goal.predictions %>%
  group_by(season, stagecode, tieid) %>%
  nest() %>%
  # head(10) %>% 
  ungroup() %>%
  sample_n(10) %>%
  # filter(tieid == '206d90db|822bd0ba') %>% 
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

# end = lubridate::now()
# 
# print(end - start)

# beepr::beep()

# win.probabilities %>% 
#   unnest(c(data)) %>% 
#   write_rds('model/v3/predictions.rds', compress = 'gz')
# 
# 
# source('model/v3/utils/plots.R')
# 
# summaries = read_rds('data/summary.rds')

summaries %>%
  right_join(win.probabilities) %>%
  mutate(
    data = map(
      data,
      ~.x %>%
        mutate(
          t1 = replace_na(t1, 0),
          pk = replace_na(pk, 0),
          predictedprobt1 = t1 + 0.5 * pk
        )
    ),
    plot = pmap(list(team1, team2, result, data, season, stagecode, aet), winprobplot)
  ) %>%
  pull(plot)
#   
# 
#   win.probabilities %>% 
#   unnest(c(data))
# 
# distributions$data[[1]] %>% tail()
# 
# map(distributions$data, tail)

# prediction.distributions
# 
# prediction.distributions %>% 
#   select(season:minuterown, dist.table) %>% 
#   unnest(c(dist.table)) %>% 
#   mutate(
#     t1 = t1.g1 + t1.g2,
#     t2 = t2.g1 + t2.g2,
#     t1.ag = t1.g2,
#     t2.ag = t2.g1,
#     winner = case_when(
#       (t1 > t2) | (t1 == t2 & t1.ag > t2.ag) ~ 't1',
#       (t2 > t1) | (t1 == t2 & t2.ag > t1.ag) ~ 't2',
#       (t1 == t2) & (t1.ag == t2.ag) ~ 'pk'
#     )
#   ) %>% 
#   group_by(season, stagecode, tieid, minuteclean, minuterown, winner) %>% 
#   summarise(prob = sum(prob)) %>% 
#   pivot_wider(names_from = winner, values_from = prob) %>% 
#   select(-t1, -t2, -pk, t1, t2, pk)
#   
