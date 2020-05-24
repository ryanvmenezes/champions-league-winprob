library(here)
library(tidyverse)

this.version = 'v2'

source(here('model', 'utils.R'))

training.data

run.glm = function(data) {
  glm(
    t1win ~ minuteclean + goalst1diff + awaygoalst1diff + redcardst1diff + probh1 + proba1,
    data = data,
    family = 'binomial'
  )
}

# one model per minute

models.2.1 = training.data %>% 
  distinct(minuteclean) %>% 
  mutate(
    data = map(minuteclean, ~training.data %>% filter(minuteclean == .x)),
    model = map(data, run.glm)
  ) %>% 
  select(-data)

models.2.1

predictions2.1 = models.2.1 %>% 
  mutate(
    predictions = map2(
      model,
      minuteclean,
      ~make.predictions(
        .x,
        data = all.data %>% filter(minuteclean == .y)
      )
    )
  ) %>% 
  select(-model, -minuteclean) %>% 
  unnest(c(predictions)) %>% 
  arrange(season, stagecode, tieid)

predictions2.1

predictions2.1 %>% write_rds(here('model', this.version, 'predictions21.rds'))

# window of data for each minute
# shrink window toward end

filter.by.minute = function(m) {
  filtered = case_when(
    m < 170 ~
      training.data %>% filter(minuteclean >= m - 10, minuteclean <= m + 10),
    m >= 170 & m < 180 ~
      training.data %>% filter(minuteclean >= m - 3, minuteclean <= m + 3),
    m == 180 ~
      training.data %>% filter(minuteclean >= m - 1, minuteclean <= m + 1),
    m > 180 & m < 210 ~
      training.data %>% filter(minuteclean >= m - 5, minuteclean <= m + 5),
    m == 210 ~
      training.data %>% filter(minuteclean >= m - 1, minuteclean <= m + 1)
  )
  return(filtered)  
}

filter.by.minute = function(m) {
  if(m < 170) {
    filtered = training.data %>%
      filter(minuteclean >= m - 10, minuteclean <= m + 10)
  }
  if(m >= 170 & m < 180) {
    filtered = training.data %>%
      filter(minuteclean >= m - 3, minuteclean <= m + 3)
  }
  if(m == 180) {
    filtered = training.data %>%
      filter(minuteclean >= m - 1, minuteclean <= m + 1)
  }
  if(m > 180 & m < 210) {
    filtered = training.data %>%
      filter(minuteclean >= m - 3, minuteclean <= m + 3)
  }
  if(m == 210) {
    filtered = training.data %>%
      filter(minuteclean >= m - 1, minuteclean <= m + 1)
  }
  return(filtered)
}

models.2.2 = training.data %>% 
  distinct(minuteclean) %>% 
  mutate(
    data = map(minuteclean, filter.by.minute),
    model = map(data, run.glm)
  ) %>% 
  select(-data)

predictions2.2 = models.2.2 %>% 
  mutate(
    predictions = map2(
      model,
      minuteclean,
      ~make.predictions(
        .x,
        data = all.data %>% filter(minuteclean == .y)
      )
    )
  ) %>% 
  select(-model, -minuteclean) %>% 
  unnest(c(predictions)) %>% 
  arrange(season, stagecode, tieid)

predictions2.2

predictions2.2 %>% write_rds(here('model', this.version, 'predictions22.rds'))
