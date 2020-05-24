library(here)
library(locfit)
library(tidyverse)

this.version = 'v1'

source(here('model', 'utils.R'))

training.data

# version 1 ---------------------------------------------------------------

model = locfit(
  t1win ~ minuteclean + goalst1diff + awaygoalst1diff + redcardst1diff + probh1 + proba1,
  data = training.data,
  family = 'binomial'
)

model

summary(model)

model %>% write_rds(here('model', this.version, 'model.rds'))