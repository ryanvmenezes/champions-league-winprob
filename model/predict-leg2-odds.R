library(here)
library(tidyverse)

set.seed(4141)

summaries = read_csv(here('data-get', 'assemble', 'matrix-leg-summary.csv'))
summaries

odds = read_csv(here('data-get', 'assemble', 'all-tie-odds.csv'))
odds
 
# minmatrix = read_rds(here('data-get', 'assemble', 'minute-matrix.rds'))
# minmatrix

tieodds = summaries %>% 
  select(season, stagecode, tieid, team1, team2) %>% 
  inner_join(odds %>% select(-comp)) %>%
  filter(season < 2020)

tieodds

# tieodds %>% count(season)

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

preds = c('h1', 'd1', 'a1')# %>% str_c('prob', .)
resps = c('h2', 'd2', 'a2')# %>% str_c('prob', .)

writeformula = function(p1, p2, r) {
  p1 = str_c('prob', p1)
  p2 = str_c('prob', p2)
  r = str_c('prob', r)
  str_c(r, ' ~ ', str_c(c(p1, p2), collapse = ' + '))
}

modelcombos = expand_grid(pred1 = preds, pred2 = preds, resp1 = resps, resp2 = resps) %>% 
  filter(pred1 != pred2) %>% 
  filter(resp1 != resp2) %>%
  mutate(
    predkey = map2_chr(pred1, pred2, ~str_c(sort(c(.x, .y)), collapse = '|')),
    respkey = map2_chr(resp1, resp2, ~str_c(sort(c(.x, .y)), collapse = '|'))
  ) %>% 
  distinct(predkey, respkey) %>% 
  separate(predkey, into = c('pred1', 'pred2')) %>% 
  separate(respkey, into = c('resp1', 'resp2')) %>% 
  mutate(
    formula1 = pmap_chr(list(pred1, pred2, resp1), writeformula),
    formula2 = pmap_chr(list(pred1, pred2, resp2), writeformula),
    combono = row_number()
  )

modelcombos

fitsstart = modelcombos %>% 
  mutate(
    trial = map(pred1, ~1:reps)
  ) %>% 
  unnest(cols = c(trial)) %>% 
  left_join(modelingdata)

fitsstart

runmodel = function(f, df) {
  lm(as.formula(f), data = df)
}

fits = fitsstart %>% 
  mutate(
    fitted1 = map2(formula1, training, runmodel),
    fitted2 = map2(formula2, training, runmodel)
  )

fits

# %>% 
#   select(pred1:resp2, trial, fitted1, fitted2) %>% 
#   mutate(glance1 = map(fitted1, broom::glance),
#          glance2 = map(fitted2, broom::glance)) %>% 
#   unnest(cols = c(glance1, glance2), names_repair = 'unique')
# 
# fits %>% 
#   select(pred1:resp2, trial, starts_with('r.sq')) %>% 
#   mutate(rsqavg = (`r.squared...8` + `r.squared...19`) / 2) %>% 
#   group_by(pred1, pred2, resp1, resp2) %>% 
#   summarise(meanrsq = mean(rsqavg)) %>% 
#   arrange(-meanrsq) %>% ungroup() %>% pull(meanrsq) %>% unique()
#   

# fits$testing[[1]]

# resp1 = 'h2'
# resp2 = 'd2'
# m1 = fits$fitted1[[1]]
# m2 = fits$fitted2[[1]]
# testing = fits$testing[[1]]

calcpredictions = function(resp1, resp2, m1, m2, testing) {
  obs1 = str_c('prob', resp1)
  obs2 = str_c('prob', resp2)
  target1 = str_c('pred', resp1)
  target2 = str_c('pred', resp2)

  testing %>% 
    mutate(
      obs1 = testing[[obs1]],
      obs2 = testing[[obs2]],
      pred1 = predict(m1, newdata = testing, type = 'response'),
      pred2 = predict(m2, newdata = testing, type = 'response'),
      se1 = (pred1 - obs1)^2,
      se2 = (pred2 - obs2)^2
    )
}

calcrmse = function(df) {
  # df %>%
  #   select(se1, se2) %>%
  #   unlist() %>%
  #   mean(na.rm = TRUE) %>%
  #   sqrt()
  
  df %>%
    summarise(
      rmse1 = sqrt(mean(se1, na.rm = TRUE)),
      rmse2 = sqrt(mean(se2, na.rm = TRUE))
    ) %>%
    unlist() %>%
    mean()
}

predictions = fits %>% 
  mutate(preds = pmap(list(resp1, resp2, fitted1, fitted2, testing), calcpredictions)) %>% 
  mutate(rmse = map_dbl(preds, calcrmse)) %>% 
  arrange(rmse)

predictions

predictions %>% pull(rmse)

# i = 66
# predictions[i,]
# predictions$preds[[i]]
# predictions$preds[[i]] %>% arrange(-se1)
# predictions$preds[[i]] %>% arrange(-se2)
# 
# 
# predictions$preds[[i]] %>% select(se1, se2) %>% unlist() %>% mean(na.rm = TRUE) %>% sqrt()
# 
# a = predictions$preds[[i]]$se1 %>% mean(na.rm = TRUE) %>% sqrt()
# b = predictions$preds[[i]]$se2 %>% mean(na.rm = TRUE) %>% sqrt()
# a
# b
# (a + b) / 2


allmodelseval = predictions %>% 
  group_by(pred1, pred2, resp1, resp2, combono) %>% 
  summarise(rmsemean = mean(rmse)) %>% 
  arrange(rmsemean)

allmodelseval

predictions %>% 
  select(pred1:resp2, combono, trial, rmse) %>% 
  spread(trial, rmse) %>% 
  left_join(allmodelseval) %>% 
  arrange(rmsemean)

predictions %>% filter(combono == 9 & trial == 1)
predictions %>% filter(combono == 9 & trial == 1) %>% pull(preds)
predictions %>% filter(combono == 9 & trial == 1) %>% pull(fitted1) %>% `[[`(1) %>% summary()
predictions %>% filter(combono == 9 & trial == 1) %>% pull(fitted2) %>% `[[`(1) %>% summary()

predictions %>% filter(combono == 3 & trial == 1)
predictions %>% filter(combono == 3 & trial == 1) %>% pull(preds)
predictions %>% filter(combono == 3 & trial == 1) %>% pull(fitted1) %>% `[[`(1) %>% summary()
predictions %>% filter(combono == 3 & trial == 1) %>% pull(fitted2) %>% `[[`(1) %>% summary()


# evaluate on r-squared ---------------------------------------------------

rsqbytrial = fits %>% 
  mutate(gl1 = map(fitted1, broom::glance),
         gl2 = map(fitted2, broom::glance)) %>% 
  unnest(c(gl1, gl2), names_repair = 'unique') %>% 
  select(pred1:resp2, combono, trial, starts_with('r.squared')) 

rsqbytrial

rsqbytrial %>% 
  ggplot(aes(r.squared...13, r.squared...24, color = as.character(combono))) +
  geom_jitter(width = 0.01)

rsqbytrial %>% 
  group_by(pred1, pred2, resp1, resp2, combono) %>% 
  summarise(rsq1 = mean(r.squared...13), rsq2 = mean(r.squared...24)) %>% 
  mutate(rsqavg = mean(c(rsq1, rsq2))) %>% 
  arrange(-rsqavg)
