library(here)
library(furrr)
library(tidyverse)

plan(multiprocess)

source(here('model', 'utils.R'))

versions = c(
    # 'v1',
    # 'v2.1',
    'v2.2'
    # 'v2.2.1'
)

for (this.version in versions) {
    predictions = read.predictions(this.version)

    plots = make.all.plots(predictions)

    export.all.plots(plots, this.version)
}
