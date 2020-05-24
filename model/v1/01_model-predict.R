library(here)
library(locfit)
library(tidyverse)

this.version = 'v1'

source(here('model', 'utils.R'))

model = locfit(
  t1win ~ minuteclean + goalst1diff + awaygoalst1diff + redcardst1diff + probh1 + proba1,
  data = training.data,
  family = 'binomial'
)

predictions = make.predictions(model, all.data)

save.predictions(predictions, this.version)
