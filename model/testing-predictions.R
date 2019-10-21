library(locfit)
library(tidyverse)

fits = read_rds('model/fits.rds')
fits

predictions = function(df, m) {
  df %>% 
    mutate(
      probwint1 = predict(m, newdata = df, type = 'response'),
      error = as.numeric(t1win) - probwint1,
      sqerror = error ^ 2
    )
}

preds = fits %>% 
  mutate(
    p1 = map2(testing, m1, predictions),
    p2 = map2(testing, m2, predictions),
    p3 = map2(testing, m3, predictions),
    p4 = map2(testing, m4, predictions),
  )

preds %>% 
  transmute(
    p1error = map_dbl(p1, ~.x %>% pull(sqerror) %>% mean() %>% sqrt()),
    p2error = map_dbl(p2, ~.x %>% pull(sqerror) %>% mean() %>% sqrt()),
    p3error = map_dbl(p3, ~.x %>% pull(sqerror) %>% mean() %>% sqrt()),
    p4error = map_dbl(p4, ~.x %>% pull(sqerror) %>% mean() %>% sqrt())
  ) %>% 
  summarise_all(mean)
