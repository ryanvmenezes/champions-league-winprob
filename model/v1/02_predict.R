library(here)
library(locfit)
library(tidyverse)

this.version = 'v1'

source(here('model', 'utils.R'))

model = read_rds(here('model', this.version, 'model.rds'))

model

summary(model)

predictions = make.predictions(model)

predictions

predictions %>% write_rds(here('model', this.version, 'predictions.rds'))
