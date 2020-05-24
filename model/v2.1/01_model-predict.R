library(here)
library(tidyverse)

this.version = 'v2.1'

source(here('model', 'utils.R'))

# one model per minute

models = training.data %>% 
  distinct(minuteclean) %>% 
  mutate(
    data = map(minuteclean, ~training.data %>% filter(minuteclean == .x)),
    model = map(data, run.glm)
  ) %>% 
  select(-data)

models

predictions = models %>% 
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

predictions

save.predictions(predictions, this.version)