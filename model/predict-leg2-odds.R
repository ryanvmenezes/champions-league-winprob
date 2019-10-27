library(here)
library(tidyverse)

set.seed(4141)

summaries = read_csv(here('data-get', 'assemble', 'matrix-leg-summary.csv'))
summaries

minmatrix = read_rds(here('data-get', 'assemble', 'minute-matrix.rds'))
minmatrix

tieodds = summaries %>% 
  select(season, stagecode, tieid, team1, team2) %>% 
  inner_join(
    minmatrix %>% 
      select(season, stagecode, tieid, starts_with('prob')) %>% 
      distinct()
  )

tieodds

tieodds %>% 
  summarise(
    hd1 = mean(probh1 + probd1, na.rm = TRUE),
    da1 = mean(probd1 + proba1, na.rm = TRUE),
    ha1 = mean(probh1 + proba1, na.rm = TRUE),
    hd2 = mean(probh2 + probd2, na.rm = TRUE),
    da2 = mean(probd2 + proba2, na.rm = TRUE),
    ha2 = mean(probh2 + proba2, na.rm = TRUE),
    leg1 = mean(probh1 + probd1 + proba1, na.rm = TRUE),
    leg2 = mean(probh2 + probd2 + proba2, na.rm = TRUE)
  )


reps = 10

modelingdata = tibble(trial = 1:reps) %>%
  mutate(
    tokeep = map(trial, ~tieodds %>% distinct(season, stagecode, tieid) %>% sample_frac(0.75)),
    training = map(tokeep, ~tieodds %>% semi_join(.x)),
    testing = map(tokeep, ~tieodds %>% anti_join(.x))
  ) %>% 
  select(-tokeep)

modelingdata

# models = list(
#   hd1h2 = function(df) lm(probh2 ~ probh1 + probd1, data = df),
#   ha1h2 = function(df) lm(probh2 ~ probh1 + proba1, data = df),
#   da1h2 = function(df) lm(probh2 ~ probd1 + proba1, data = df),
#   hd1d2 = function(df) lm(probd2 ~ probh1 + probd1, data = df),
#   ha1d2 = function(df) lm(probd2 ~ probh1 + proba1, data = df),
#   da1d2 = function(df) lm(probd2 ~ probd1 + proba1, data = df),
#   hd1a2 = function(df) lm(proba2 ~ probh1 + probd1, data = df),
#   ha1a2 = function(df) lm(proba2 ~ probh1 + proba1, data = df),
#   da1a2 = function(df) lm(proba2 ~ probd1 + proba1, data = df)
# )

preds = c('h1', 'd1', 'a1') %>% str_c('prob', .)
resps = c('h2', 'd2', 'a2') %>% str_c('prob', .)

writeformula = function(p1, p2, r) {
  str_c(r, ' ~ ', str_c(c(p1, p2), collapse = ' + '))
}

fitsstart = expand_grid(pred1 = preds, pred2 = preds, resp1 = resps, resp2 = resps) %>% 
  filter(pred1 != pred2) %>% 
  filter(resp1 != resp2) %>% 
  mutate(
    formula1 = pmap_chr(list(pred1, pred2, resp1), writeformula),
    formula2 = pmap_chr(list(pred1, pred2, resp2), writeformula)
  ) %>% 
  mutate(
    trial = map(pred1, ~1:reps)
  ) %>% 
  unnest(cols = c(trial)) %>% 
  left_join(modelingdata)

fitsstart  

fitsstart = tibble(
  modelname = names(models),
  data = map(modelname, ~modeling)
) %>% 
  unnest(data)

fitsstart

fits = fitsstart %>% 
  mutate(fittedmodel = map2(modelname, training, ~models[[.x]](.y)))

calcpredictions = function(df, m, mname) {
  target = str_sub(mname, start = -2)
  targetvar = str_c('pred', target)
  df %>% 
    mutate(
      pred = predict(m, newdata = df, type = 'response')
    ) %>% 
    rename(!!targetvar := pred)
}

predictions = fits %>% 
  mutate(preds = pmap(list(testing, fittedmodel, modelname), calcpredictions))

predictions

predictions$preds[[1]]

predictions$fittedmodel[[1]]$terms %>% str()
