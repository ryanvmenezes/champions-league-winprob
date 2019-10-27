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
    probh1, probd1, proba1, probh2, probd2, proba2
  ) %>% 
  mutate(
    probh1 = replace_na(probh1, 0.33),
    probd1 = replace_na(probd1, 0.33),
    proba1 = replace_na(proba1, 0.33),
    probh2 = replace_na(probh2, 0.33),
    probd2 = replace_na(probd2, 0.33),
    proba2 = replace_na(proba2, 0.33),
    probh2 = case_when(minuteclean <= 90 ~ 0, TRUE ~ probh2),
    probd2 = case_when(minuteclean <= 90 ~ 0, TRUE ~ probd2),
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

models = list(
  # just goals
  m1 = function(df) {
    locfit(
      t1win ~ minuteclean + 
        goalst1diff + 
        awaygoalst1diff,
      data = df,
      family = 'binomial'
    )
  },
  # goals and red cards
  m2 = function(df) {
    locfit(
      t1win ~ minuteclean + 
        goalst1diff + 
        awaygoalst1diff + 
        redcardst1diff,
      data = df,
      family = 'binomial'
    )
  },
  # add in odds from before leg 1
  m3 = function(df) {
    locfit(
      t1win ~ minuteclean + 
        goalst1diff + 
        awaygoalst1diff + 
        redcardst1diff + 
        probh1 +
        probd1,
      data = df,
      family = 'binomial'
    )
  },
  # at change of game, start using odds for leg 2
  m4 = function(df) {
    locfit(
      t1win ~ minuteclean + 
        goalst1diff + 
        awaygoalst1diff + 
        redcardst1diff + 
        probh1 + 
        probd1 +
        probh2 +
        probd2,
      data = df,
      family = 'binomial'
    )
  }
)

models$m1(modeling$training[[1]])

models$m2(modeling$training[[1]])

models$m3(modeling$training[[1]])

models$m4(modeling$training[[1]])


fitsstart = tibble(
  modelno = 1:length(models),
  model = models,
  data = map(model, ~modeling)
) %>% 
  unnest(data)

fitsstart

fitmodel = function (m, df) {
  m(df)
  pb$tick()$print()
}

pb = progress_estimated(nrow(fitsstart))
fits = fitsstart %>% 
  mutate(fittedmodel = map2(model, training, fitmodel))
# 
# fits = modeling %>% 
#   mutate(
#     m1 = map(training, model1),
#     m2 = map(training, model2),
#     m3 = map(training, model3),
#     m4 = map(training, model4)
#   )
# 
# fits %>% 
#   write_rds(here('model', 'fits.rds'), compress = 'gz')
# 
# minmatrixtrim %>% 
#   write_rds(here('model', 'min-matrix-trim.rds'), compress = 'gz')
