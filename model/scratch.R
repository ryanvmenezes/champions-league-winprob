library(here)
library(tidyverse)

source(here('model', 'utils.R'))

predictions = read_rds('model/predictions/v2.1.rds')
predictions1 = read_rds('model/predictions/v2.2.rds')
predictions2 = read_rds('model/predictions/v2.2.1.rds')


plots.tmp = summaries %>% 
  filter(aet) %>% 
  left_join(predictions1) %>% 
  left_join(predictions2 %>% select(season, stagecode, tieid, minuteclean, minuterown, predictedprobt1.smooth = predictedprobt1)) %>% 
  left_join(predictions %>% select(season, stagecode, tieid, minuteclean, minuterown, predictedprobt1.bymin = predictedprobt1)) %>% 
  group_by(season, stagecode, tieid, team1, team2, winner) %>%
  nest() %>% 
  mutate(
    plot = map(
      data,
      ~.x %>% 
        winprobplot.simple() +
        geom_line(aes(y = predictedprobt1.smooth), color = 'red') +
        geom_line(aes(y = predictedprobt1.bymin), color = 'green') +
        geom_vline(xintercept = 180, linetype = 'dashed')
    )
  )

plots.tmp %>%
  ungroup() %>% 
  sample_n(5) %>% 
  print() %>% 
  pull(plot)

training.data %>%
  distinct(minuteclean) %>%
  mutate(
    data = map(minuteclean, filter.by.minute),
    rows = map_int(data, nrow)
  ) %>% 
  select(-data) %>% 
  write_csv('model/rows-per-window.csv')

read_csv('model/evaluation/compare-log-lik.csv')
