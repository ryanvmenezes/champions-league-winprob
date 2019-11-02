library(here)
library(locfit)
library(tidyverse)

minmatrix = read_rds(here('data-get', 'assemble', 'minute-matrix.rds'))

minmatrix

minmatrixtrim = minmatrix %>%
  filter(season < 2020) %>% 
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

minmatrixtrim

model = locfit(
  t1win ~ minuteclean + goalst1diff + awaygoalst1diff + redcardst1diff + proba1 + probd1,
  data = minmatrixtrim,
  family = 'binomial'
)

model

summary(model)

model %>% write_rds(here('model', 'final-model.rds'))

predictions = minmatrixtrim %>% 
  mutate(predictedprobt1 = predict(model, newdata = minmatrixtrim, type = 'response')) %>% 
  select(season, stagecode, tieid, minuteclean, minuterown, predictedprobt1)

predictions %>% 
  group_by(season, stagecode, tieid) %>% 
  nest() %>% 
  pull(data) %>% 
  `[[`(1070) %>% 
  ggplot(aes(minuteclean, predictedprobt1)) +
  geom_line() +
  scale_x_continuous(
    breaks = c(0, 45, 90, 135, 180, 210),
    labels = c('g1 start','g1 half','g1 end\ng2 start','g2 half','g2 end\net start','et end')
  ) +
  scale_y_continuous(limits = c(0,1))

predictions %>%
  write_rds(here('model', 'min-matrix-trim.rds'), compress = 'gz')
