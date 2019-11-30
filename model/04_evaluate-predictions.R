library(here)
library(tidyverse)

predictions = read_rds(here('model', 'predictions.rds'))

predictions

predictions %>% 
  select(season, stagecode, tieid, t1win, predictedprobt1)
