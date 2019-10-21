library(here)
library(locfit)
library(tidyverse)

set.seed(4141)

datamatrix = read_rds(here('data-get', 'assemble', 'minute-matrix.rds'))

# minmatrix

# minmatrixtrim = minmatrix %>% 
#   group_by(season, stagecode, tieid) %>% 
#   mutate(rown = row_number()),
#   select(
#     season, stagecode, tieid,
#     t1win, minuteclean
#   )

datamatrix

modeling = tibble(trial = 1:10) %>% 
  mutate(
    training = map(trial, ~sample_frac(datamatrix, 0.75)),
    testing = map(training, ~datamatrix %>% anti_join(.x))
  )

modeling

# just goals
model1 = function(df) {
  locfit(
    t1win ~ minuteclean + 
      goalst1diff + 
      awaygoalst1diff,
    data = df,
    family = 'binomial'
  )
}

# goals and red cards
model2 = function(df) {
  locfit(
    t1win ~ minuteclean + 
      goalst1diff + 
      awaygoalst1diff + 
      redcardst1diff,
    data = df,
    family = 'binomial'
  )
}

# add in odds from before leg 1
model3 = function(df) {
  locfit(
    t1win ~ minuteclean + 
      goalst1diff + 
      awaygoalst1diff + 
      redcardst1diff + 
      probh1 + 
      proba1,
    data = df,
    family = 'binomial'
  )
}


fits = modeling %>% 
  mutate(
    m1 = map(training, model1),
    m2 = map(training, model2),
    m3 = map(training, model3)
  )

predictions = function(df, m) {
  predict(m, newdata = df, type = "response")
}

calculateerrors = function(df) {
  df %>% 
    mutate(error = )
}

fits %>% 
  mutate(
    p1 = map2(testing, m1, predictions),
    p2 = map2(testing, m2, predictions),
    p3 = map2(testing, m3, predictions)
  )

# errors = winprob %>% 
#   mutate(
#     errorN = t1win - neutral,
#     errorO = t1win - pregameodds,
#     errorO2 = t1win - pregameodds2,
#     errorO3 = t1win - pregameodds3,
#     sqrErrorN = errorN^2,
#     sqrErrorO = errorO^2,
#     sqrErrorO2 = errorO2^2,
#     sqrErrorO3 = errorO3^2
#   ) %>% 
#   group_by(made_minute) %>% 
#   summarise(
#     count = n(),
#     neutral = sqrt(mean(sqrErrorN)),
#     pregameodds = sqrt(mean(sqrErrorO)),
#     pregameodds2 = sqrt(mean(sqrErrorO2)),
#     pregameodds3 = sqrt(mean(sqrErrorO3))
#   )