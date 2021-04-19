library(tidyverse)
library(furrr)

plan(multisession)
beepr::beep()

predictions = read_rds('model/predictions/v3.rds')

predictions

summaries = read_rds('data/summary.rds')

summaries

source('model/v3/utils/plots.R')

plots = summaries %>% 
  right_join(
    predictions %>% 
      group_by(season, stagecode, tieid, t1win) %>% 
      nest()
  ) %>%
  sample_n(10) %>% 
  mutate(plot = future_pmap(list(team1, team2, result, data, season, stagecode, aet), winprobplot, .progress = TRUE))