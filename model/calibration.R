library(tidyverse)

preds = read_rds('model/v3/predictions.rds')

preds

calib.calc = preds %>%
  filter(minuterown != max(minuterown)) %>% 
  ungroup() %>% 
  filter(season == 2019) %>% 
  select(predictedprobt1, t1win) %>% 
  mutate(predbin = cut(predictedprobt1, breaks = c(-Inf, 0.01, 0.05, .1, .2, .3, .4, .5, .6, .7, .8, .9, .95, .99, 1))) %>% 
  group_by(predbin) %>% 
  summarise(
    preds = n(),
    success = sum(t1win),
    actual.prob = success / preds,
  ) %>% 
  mutate(
    predbin = levels(predbin),
    predbin = str_remove_all(predbin, '\\(|\\]'),
    predbin = str_replace(predbin, '-Inf', '0')
  ) %>% 
  separate(
    predbin, 
    into = c('lo','hi'),
    sep = ','
  )

calib.calc

calib.calc %>% write_csv('model/evaluation/calibration.csv', na = '')
