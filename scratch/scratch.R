library(here)
library(tidyverse)

source(here('model', 'utils.R'))
# 
# predictions = read_rds('model/predictions/v2.1.rds')
predictions1 = read_rds('model/predictions/v2.2.rds')
predictions2 = read_rds('model/predictions/v2.2.1.rds')

library(furrr)
plan(multiprocess)

# plots.tmp = summaries %>% 
#   left_join(predictions1) %>% 
#   left_join(predictions2 %>% select(season, stagecode, tieid, minuteclean, minuterown, predictedprobt1.smooth = predictedprobt1)) %>% 
#   left_join(predictions %>% select(season, stagecode, tieid, minuteclean, minuterown, predictedprobt1.bymin = predictedprobt1)) %>% 
#   group_by(season, stagecode, tieid, team1, team2, winner) %>%
#   nest() %>% 
#   mutate(
#     plot = map(
#       data,
#       ~.x %>% 
#         winprobplot.simple() +
#         geom_line(aes(y = predictedprobt1.smooth), color = 'red') +
#         geom_line(aes(y = predictedprobt1.bymin), color = 'green') +
#         geom_vline(xintercept = 180, linetype = 'dashed')
#     )
#   )

plots.tmp %>%
  # filter(season == 2020) %>% 
  ungroup() %>% 
  sample_n(5) %>% 
  print() %>% 
  pull(plot)



read_csv('model/evaluation/compare-log-lik.csv')


predictions2 %>% 
  group_by(season, stagecode, tieid) %>% 
  filter(minuterown == max(minuterown)) %>% 
  right_join(summaries) %>% 
  filter(predictedprobt1 != 0) %>% 
  filter(predictedprobt1 != 1) %>% 
  filter(!pk) %>% 
  view()


match.data = summaries %>% 
  filter(team1 == 'Young Boys') %>% 
  filter(team2 == 'Red Star') %>% 
  left_join(predictions2) %>% 
  view()

filtered.predictions %>% 
  select(predictedprobt1, minuteclean, minuterown) %>% 
  