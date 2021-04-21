library(tidyverse)

summaries = read_rds('data/summary.rds')

summaries

win.probabilities = read_rds('model/v3/probabilities.rds')

win.probabilities

minutes = read_rds('model/v3/predictors/minutes.rds')

minutes

preds = minutes %>% 
  select(
    season, stagecode, tieid,
    minuteclean, minuterown,
    tieid, t1win,
    is.goal, is.away.goal, is.red.card,
    goals.t1, goals.t2,
    away.goals.t1, away.goals.t2,
    players.t1, players.t2
  ) %>% 
  group_by(season, stagecode, tieid) %>% 
  mutate(
    eventteam = case_when(
      goals.t1 != lag(goals.t1) | players.t1 != lag(players.t1) ~ 1,
      goals.t2 != lag(goals.t2) | players.t2 != lag(players.t2) ~ 2,
    )
  ) %>% 
  ungroup() %>% 
  left_join(
    minutes %>% 
      select(season, stagecode, tieid, minuteclean, minuterown, player, playerid, eventtype, actualminute) %>% 
      drop_na(player)
  ) %>% 
  left_join(
    win.probabilities %>% 
      mutate(
        predictedprobt1 = replace_na(t1, 0) + 0.5 * replace_na(pk, 0),
      ) %>% 
      select(season, stagecode, tieid, minuteclean, minuterown, predictedprobt1)
  ) %>% 
  mutate(
    likelihood = case_when(
      t1win == FALSE ~ 1 - predictedprobt1,
      t1win == TRUE ~ predictedprobt1
    ),
    error = as.numeric(t1win) - predictedprobt1,
    sqerror = error ^ 2
  ) %>% 
  group_by(season, stagecode, tieid, t1win) %>% 
  mutate(chgpredictedprobt1 = replace_na(predictedprobt1 - lag(predictedprobt1), 0))

# preds %>% filter(season == 2017, tieid == '206d90db|e2d8892c') %>% view()

preds

preds %>% write_rds('model/v3/predictions.rds', compress = 'gz')
preds %>% write_csv('model/v3/predictions.csv', na = '')

# preds %>% write_rds('model/predictions/v3.rds', compress = 'gz')
# preds %>% write_csv('model/predictions/v3.csv')