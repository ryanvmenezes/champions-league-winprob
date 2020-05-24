library(here)
library(furrr)
library(tidyverse)

this.version = 'v2'

source(here('model', 'utils.R'))

plan(multiprocess)
availableCores()

predictions = read_rds(here('model', this.version, 'predictions22.rds'))

predictions

plots = make.all.plots(predictions)

plots

# plots %>% write_rds(here('model', this.version, 'all-plots.rds'), compress = 'gz')

# plots = read_rds(here('model', this.version, 'all-plots.rds'))

export.all.plots(plots, plotsfolder =  here('model', this.version, 'plots'))