library(tidyverse)

predictions = read_rds('model/predictions/v3.rds')

predictions

summaries = read_rds('data/summary.rds')

summaries
# 
# minutes = read_rds('model/v3/predictors/minutes.rds')
# 
# minutes
# 
# minutes

tie.wp.summary = predictions %>% 
  group_by(season, stagecode, tieid, t1win) %>% 
  nest() %>% 
  mutate(
    excitement = map_dbl(
      data,
      ~.x %>% 
        mutate(
          chg.prob = replace_na(abs(predictedprobt1 - lag(predictedprobt1)), 0)
        ) %>% 
        summarise(chg.prob = sum(chg.prob)) %>% 
        pull()
    ),
    tension = map_dbl(
      data,
      ~.x %>% 
        mutate(
          tension = abs(predictedprobt1 - 0.5),
        ) %>% 
        summarise(tension = sum(tension)) %>% 
        pull()
    ),
    comeback = map2_dbl(
      data,
      t1win,
      ~{
        if (.y) {
          min.prob = .x %>% pull(predictedprobt1) %>% min()
        } else {
          min.prob = (1 - .x %>% pull(predictedprobt1)) %>% min()
        }
        min.prob
      }
    )
  ) %>% 
  left_join(summaries) %>% 
  select(-data) %>% 
  right_join(summaries)

tie.wp.summary

tie.wp.summary %>% write_csv('model/v3/tie-wp-summary.csv', na = '')