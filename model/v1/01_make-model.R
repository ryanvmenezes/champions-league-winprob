library(here)
library(locfit)
library(tidyverse)

source(here('model', 'v1', 'utils.R'))

predmatrix

# version 1 ---------------------------------------------------------------

model = locfit(
  t1win ~ minuteclean + goalst1diff + awaygoalst1diff + redcardst1diff + probh1 + proba1,
  data = predmatrix,
  family = 'binomial'
)

model

summary(model)

model %>% write_rds(here('model', this.version, 'model.rds'))

# gcvstat = gcv(model) 
# gcvstat %>% write_file(here('model', this.version, 'gcv.txt'))
