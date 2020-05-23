library(here)
library(furrr)
library(locfit)
library(tidyverse)

plan(multiprocess)

summaries = read_rds(here('data', 'summary.rds'))
odds = read_rds(here('data', 'odds.rds'))
events = read_rds(here('data', 'events.rds'))

summaries
odds
events

predmatrix = summaries %>% 
  filter(season < 2020) %>% 
  filter(has_events) %>% 
  filter(!has_invalid_match) %>% 
  left_join(events) %>% 
  left_join(odds) %>% 
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

predmatrix

# # set up intervals
# minute.interval = 10
# intervals = seq(0, 210 - 1, minute.interval)

# various smoothing windows to try
windows = c(0.5, 0.2, 0.1, 0.09, 0.08, 0.07, 0.06, 0.05, 0.04, 0.03, 0.02, 0.01)

set.seed(41)

predmatrix.train.test = predmatrix %>% 
  left_join(
    predmatrix %>% 
      distinct(season, stagecode, tieid) %>% 
      mutate(tiegroup = map_int(tieid, ~sample.int(4)[1]))
  )

predmatrix.train.test

window.data = tibble(window = windows) %>% 
  mutate(
    train.data = map(window, ~predmatrix.train.test %>% filter(tiegroup <= 3)),
    test.data = map(window, ~predmatrix.train.test %>% filter(tiegroup == 4))
  )

window.data
  
  # start.interval = intervals,
  # end.interval = start.interval + 10,
#   interval.data = map2(
#     start.interval,
#     end.interval,
#     ~predmatrix %>%
#       filter(minuteclean > .x & minuteclean <= .y)
#   )
# ) %>% 
#   expand_grid(window = windows)
# 
# train.test.by.interval

model.by.window = function(train.data, window) {
  locfit(
    t1win ~ lp(minuteclean + goalst1diff + awaygoalst1diff + redcardst1diff + probh1 + proba1, nn = window),
    data = train.data,
    family = 'binomial'
  )
}

# gcv.by.window = function(train.data, window) {
#   gcv(
#     t1win ~ lp(minuteclean + goalst1diff + awaygoalst1diff + redcardst1diff + probh1 + proba1, nn = window),
#     data = train.data,
#     family = 'binomial'
#   )
# }

models = window.data %>% 
  mutate(
    model = future_map2(train.data, window, model.by.window, .progress = TRUE),
    predictions = future_map2(
      test.data,
      model,
      ~.x %>% 
        mutate(predictedprobt1 = predict(.y, newdata = ., type = 'response'))
    )
  )

models

predictions = models %>% 
  select(window, predictions) %>% 
  unnest(c(predictions)) %>% 
  mutate(minute.bin = (((minuteclean - 1) %/% 5) + 1) * 5)

eval.pred.by.window = predictions %>% 
  mutate(
    error = as.numeric(t1win) - predictedprobt1,
    sqerror = error ^ 2
  ) %>% 
  group_by(window, minute.bin) %>% 
  summarise(
    rmserror = sqrt(mean(sqerror))
  ) %>% 
  arrange(minute.bin)

eval.pred.by.window

# model.eval = models %>% 
#   group_by(start.interval, end.interval) %>% 
#   mutate(mingcv = gcvstat == min(gcvstat)) %>% 
#   ungroup() %>% 
#   select(ends_with('val'), window, gcvstat, mingcv)
# 
# model.eval
# 
# model.choice.plot = model.eval %>% 
#   filter(mingcv) %>% 
#   ggplot(aes(start.interval, window)) +
#   geom_line() + 
#   geom_point() +
#   scale_y_continuous(breaks = windows) +
#   scale_x_continuous(breaks = c(45,90,135,180,210)) +
#   theme_minimal()
# 
# model.choice.plot
# 
# ggsave(here('model', 'v2', 'evaluation', 'model-choice.png'), model.choice.plot)
# 
# # just go with the best GCV (min) for each interval
# 
# final.models = models %>% 
#   group_by(start.interval, end.interval) %>% 
#   filter(gcvstat == min(gcvstat)) %>% 
#   ungroup()
# 
# final.models
# 
# final.models %>% write_rds(here('model', 'v2', 'models.rds'), compress = 'gz')
