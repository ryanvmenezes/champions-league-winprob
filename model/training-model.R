library(here)
library(locfit)
library(tidyverse)

set.seed(4141)

minmatrix = read_rds(here('data-get', 'assemble', 'minute-matrix.rds'))

minmatrix

minmatrixtrim = minmatrix %>%
  select(
    season, stagecode, tieid,
    t1win, minuteclean, minuterown,
    goalst1diff, awaygoalst1diff, redcardst1diff,
    probh1, proba1, probh2, proba2
  ) %>% 
  mutate(
    probh1 = replace_na(probh1, 0.33),
    proba1 = replace_na(proba1, 0.33),
    probh2 = replace_na(probh2, 0.33),
    proba2 = replace_na(proba2, 0.33),
    probh2 = case_when(minuteclean <= 90 ~ 0, TRUE ~ probh2),
    proba2 = case_when(minuteclean <= 90 ~ 0, TRUE ~ proba2)
  )

minmatrixtrim

modelingties = tibble(trial = 1:5) %>% 
  mutate(
    tokeep = map(trial, ~minmatrixtrim %>% distinct(season, stagecode, tieid) %>% sample_frac(0.75)),
    training = map(tokeep, ~minmatrixtrim %>% semi_join(.x)),
    testing = map(tokeep, ~minmatrixtrim %>% anti_join(.x))
  )

modelingties

modelingrows = tibble(trial = 6:10) %>% 
  mutate(
    tokeep = map(trial, ~minmatrixtrim %>% distinct(season, stagecode, tieid, minuterown) %>% sample_frac(0.75)),
    training = map(tokeep, ~minmatrixtrim %>% semi_join(.x)),
    testing = map(tokeep, ~minmatrixtrim %>% anti_join(.x))
  )

modelingrows

modeling = modelingties %>% 
  bind_rows(modelingrows) %>% 
  select(-tokeep)

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

model1(modeling$training[[1]])

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

model2(modeling$training[[1]])

# add in odds from before leg 1
model3 = function(df) {
  locfit(
    t1win ~ minuteclean + 
      goalst1diff + 
      awaygoalst1diff + 
      redcardst1diff + 
      probh1,
    data = df,
    family = 'binomial'
  )
}

model3(modeling$training[[1]])

# at change of game, start using odds for leg 2
model4 = function(df) {
  locfit(
    t1win ~ minuteclean + 
      goalst1diff + 
      awaygoalst1diff + 
      redcardst1diff + 
      probh1 + 
      probh2,
    data = df,
    family = 'binomial'
  )
}

model4(modeling$training[[1]])

fits = modeling %>% 
  mutate(
    m1 = map(training, model1),
    m2 = map(training, model2),
    m3 = map(training, model3),
    m4 = map(training, model4)
  )

fits %>% 
  write_rds(here('model', 'fits.rds'), compress = 'gz')

minmatrixtrim %>% 
  write_rds(here('model', 'min-matrix-trim.rds'), compress = 'gz')





# 
# predictions = function(df, m) {
#   predict(m, newdata = df, type = "response")
# }
# 
# calculateerrors = function(df) {
#   df %>% 
#     mutate(error = )
# }
# 
# fits %>% 
#   mutate(
#     p1 = map2(testing, m1, predictions),
#     p2 = map2(testing, m2, predictions),
#     p3 = map2(testing, m3, predictions)
#   )

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