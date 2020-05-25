library(here)
library(furrr)
library(tidyverse)

this.version = 'v2.2.1'

source(here('model', 'utils.R'))

plan(multiprocess)

predictions = read.predictions(this.version)

plots = make.all.plots(predictions)

export.all.plots(plots, this.version)