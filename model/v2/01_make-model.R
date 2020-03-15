library(here)
# library(furrr)
library(locfit)
library(tidyverse)

# plan(multisession)
# availableCores()

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

# set up train - test split
minute.interval = 10
intervals = seq(0, 210 - 1, minute.interval)

# various smoothing windows to try
windows = c(0.5, 0.25, 0.15, 0.05, 0.025, 0.01, 0.005)

set.seed(41)

train.test.by.interval = tibble(
  start.interval = intervals,
  end.interval = start.interval + 10,
  interval.data = map2(
    start.interval,
    end.interval,
    ~predmatrix %>%
      filter(minuteclean > .x & minuteclean <= .y)
  ),
  train.data = map(
    interval.data,
    ~.x %>%
      sample_frac(.75)
  ),
  test.data = map2(
    interval.data,
    train.data,
    ~.x %>%
      anti_join(.y, by = c("season", "stagecode", "tieid", "t1win", "minuteclean", "minuterown"))
  )
) %>% 
  expand_grid(window = windows)

train.test.by.interval

model.by.window = function(train.data, window) {
  locfit(
    t1win ~ lp(minuteclean + goalst1diff + awaygoalst1diff + redcardst1diff + probh1 + proba1, nn = window),
    data = train.data,
    family = 'binomial'
  )
}

# run.models = function(df) {
#   df %>% 
#     mutate(model = map2(train.data, window, model.by.window))
# }
# 
# chunk01 = run.models(train.test.by.interval[1:10,])
# chunk02 = run.models(train.test.by.interval[11:20,])
# chunk03 = run.models(train.test.by.interval[21:30,])
# chunk04 = run.models(train.test.by.interval[31:40,])
# chunk05 = run.models(train.test.by.interval[41:50,])
# chunk06 = run.models(train.test.by.interval[51:60,])
# chunk07 = run.models(train.test.by.interval[61:70,])
# chunk08 = run.models(train.test.by.interval[71:80,])
# chunk09 = run.models(train.test.by.interval[81:90,])
# chunk10 = run.models(train.test.by.interval[91:100,])
# chunk11 = run.models(train.test.by.interval[101:110,])
# chunk12 = run.models(train.test.by.interval[111:120,])
# chunk13 = run.models(train.test.by.interval[121:130,])
# chunk14 = run.models(train.test.by.interval[131:140,])
# chunk15 = run.models(train.test.by.interval[141:147,])
# 
# for (i in 1:nrow(train.test.by.interval)) {
#   row = train.test.by.interval %>% filter(row_number() == i) 
#   if (row$start.interval >= 180 & row$window < 0.01) {
#     next
#   }
#   done = row %>% run.models()
#   print(row %>% select(-ends_with('.data')))
# }
# 
# 
# chunk01

models = train.test.by.interval %>% 
  filter(!(start.interval >= 180 & window < 0.01)) %>% # take out low-n small-window models
  mutate(model = map2(train.data, window, safely(model.by.window)))

models

beepr::beep()
