library(here)
library(tidyverse)

this.version = 'v2.2'

source(here('model', 'utils.R'))

models = training.data %>%
  distinct(minuteclean) %>%
  mutate(
    data = map(minuteclean, filter.by.minute),
    model = map(data, run.glm)
  ) %>%
  select(-data)

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
