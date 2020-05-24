library(here)
library(furrr)
library(tidyverse)

this.version = 'v1'

source(here('model', 'utils.R'))

plan(multiprocess)

predictions = read_rds(here('model', this.version, 'predictions.rds'))

plots = make.all.plots(predictions)

export.all.plots(plots, plotsfolder =  here('model', this.version, 'plots'))