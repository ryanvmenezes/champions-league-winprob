library(here)
library(locfit)
library(tidyverse)

set.seed(4141)

minmatrix = read_rds(here('data-get', 'assemble', 'minute-matrix.rds'))

minmatrix

minmatrixtrim = minmatrix %>%
  filter(season < 2020) %>% 
  select(
    season, stagecode, tieid,
    t1win, minuteclean, minuterown,
    goalst1diff, awaygoalst1diff, redcardst1diff,
    probh1, probd1, proba1,
    # probh2, probd2, proba2
  ) %>% 
  mutate(
    probh1 = replace_na(probh1, 0.33),
    probd1 = replace_na(probd1, 0.33),
    proba1 = replace_na(proba1, 0.33)
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
  mhd = function(df) {
    locfit(
      t1win ~
        minuteclean +
        goalst1diff +
        awaygoalst1diff + 
        probh1 +
        probd1,
      data = df,
      family = 'binomial'
    )
  },
  mha = function(df) {
    locfit(
      t1win ~
        minuteclean +
        goalst1diff +
        awaygoalst1diff + 
        probh1 +
        proba1,
      data = df,
      family = 'binomial'
    )
  },
  mad = function(df) {
    locfit(
      t1win ~
        minuteclean +
        goalst1diff +
        awaygoalst1diff + 
        proba1 +
        probd1,
      data = df,
      family = 'binomial'
    )
  }
)

# for (i in 1:length(models)) {
#   models[[i]](modeling$training[[1]])
# }

names(models)

fitsstart = tibble(
  modelno = 1:length(models),
  modelname = str_replace(names(models), 'm', ''),
  model = models,
  data = map(model, ~modeling)
) %>% 
  unnest(data)

fitsstart

fitmodel = function (m, df) {
  pb$tick()$print()
  m(df)
}

pb = progress_estimated(nrow(fitsstart))
fits = fitsstart %>% 
  mutate(fittedmodel = map2(model, training, fitmodel))

fits

fits %>%
  write_rds(here('model', 'fits.rds'), compress = 'gz')

minmatrixtrim %>%
  write_rds(here('model', 'min-matrix-trim.rds'), compress = 'gz')
