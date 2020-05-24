library(here)
library(furrr)
library(tidyverse)

plan(multiprocess)

source('model/utils.R')

predmatrix

filter.by.minute = function(m) {
  if(m < 170) {
    filtered = predmatrix %>%
      filter(minuteclean >= m - 10, minuteclean <= m + 10)
  }
  if(m >= 170 & m < 175) {
    filtered = predmatrix %>%
      filter(minuteclean >= m - 3, minuteclean <= m + 3)
  }
  if(m >= 175 & m < 180) {
    filtered = predmatrix %>%
      filter(minuteclean >= m - 1, minuteclean <= m + 1, minuteclean <= 180)
  }
  if(m == 180) {
    filtered = predmatrix %>%
      filter(minuteclean == 180)
  }
  if(m > 180 & m <= 205) {
    filtered = predmatrix %>%
      filter(minuteclean >= m - 5, minuteclean <= m + 5, minuteclean > 180)
  }
  if(m > 205) {
    filtered = predmatrix %>%
      filter(minuteclean >= m - 1, minuteclean <= m + 1, minuteclean > 180)
  }
  return(filtered)
}

predmatrix.nested = predmatrix %>% 
  distinct(minuteclean) %>% 
  mutate(
    data = map(minuteclean, filter.by.minute)
  )

predmatrix.nested

predmatrix.nested %>% filter(minuteclean <= 185) %>% tail()

predmatrix.nested %>% tail()

run.glm = function(data) {
  glm(
    t1win ~ minuteclean + goalst1diff + awaygoalst1diff + redcardst1diff + probh1 + proba1,
    data = data,
    family = 'binomial'
  )
}

models = predmatrix.nested %>% 
  mutate(
    model = future_map(data, run.glm, .progress = TRUE),
    predictions = future_map2(
      data,
      model,
      ~.x %>% 
        mutate(predictedprobt1 = predict(.y, newdata = ., type = 'response')),
      .progress = TRUE
    )
  )

models

tail(models)

predictions = models %>%
  select(predictions) %>% 
  unnest(c(predictions)) %>% 
  group_by(season, stagecode, tieid, t1win, minuteclean, minuterown, goalst1diff, awaygoalst1diff, redcardst1diff, probh1, probd1, proba1) %>% 
  summarise(predictedprobt1 = mean(predictedprobt1)) %>% 
  arrange(season, stagecode, tieid, minuterown) %>% 
  ungroup()

predictions

game = predictions %>% 
  filter(tieid == '361ca564|e0652b02', season == 2018)

winprobplot = function(data) {
  data %>% 
    ggplot(aes(minuteclean, predictedprobt1)) +
    geom_line() +
    scale_y_continuous(limits = c(0,1)) +
    scale_x_continuous(breaks = c(0,45,90,135,180)) +
    theme_minimal()
}

game %>% 
  mutate(predictedprobt1 = if_else(minuteclean == 180, as.numeric(t1win), predictedprobt1)) %>% 
  winprobplot()

game %>% 
  filter(
    minuteclean == 1 |
      (goalst1diff != lag(goalst1diff)) |
      (goalst1diff != lead(goalst1diff)) |
      minuteclean == 180
  ) %>% 
  mutate(predictedprobt1 = if_else(minuteclean == 180, as.numeric(t1win), predictedprobt1)) %>% 
  select(-starts_with('prob')) %>% 
  winprobplot()


  
