library(tidyverse)

summaries = read_rds('data/summary.rds')

summaries

win.probabilities = read_rds('model/v3/probabilities.rds')

win.probabilities

minutes = read_rds('model/v3/predictors/minutes.rds')

minutes

preds = minutes %>% 
  select(season, stagecode, tieid, minuteclean, minuterown, tieid, t1win, is.goal, is.away.goal, is.red.card) %>% 
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
  )

preds

preds %>% write_rds('model/v3/predictions.rds', compress = 'gz')
preds %>% write_csv('model/v3/predictions.csv')

# preds %>% write_rds('model/predictions/v3.rds', compress = 'gz')
# preds %>% write_csv('model/predictions/v3.csv')