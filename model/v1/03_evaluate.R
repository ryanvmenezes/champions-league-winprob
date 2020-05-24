library(here)
library(tidyverse)

this.version = 'v1'

source(here('model', 'utils.R'))

predictions = read_rds(here('model', this.version, 'predictions.rds'))

predictions

# log likelihoods ---------------------------------------------------------

llbytie = calculate.ll.by.tie(predictions)

llbytie

llbytie %>% tail()

llbyminute = calculate.ll.by.minute(predictions)

llbyminute

llbyminuteplot = llbyminute %>% 
  ggplot(aes(minuteclean, loglik, color = predset)) +
  geom_line() +
  theme_minimal()

llbyminuteplot

evalfolder = here('model', this.version, 'evaluation')

llbytie %>% write_csv(file.path(evalfolder, 'loglik-by-tie.csv'), na = '')
llbyminute %>% write_csv(file.path(evalfolder, 'loglik-by-minute.csv'), na = '')
ggsave(file.path(evalfolder, 'loglik-by-minute.png'), llbyminuteplot, width = 10, height = 5)

# errors ------------------------------------------------------------------

rmserrors = calculate.rms.errors.by.minute(predictions)

rmserrors

rmserrorsplot = rmserrors %>% 
  ggplot(aes(minuteclean, rmserror, color = predset)) +
  geom_line() +
  theme_minimal()

rmserrorsplot

rmserrors %>% write_csv(file.path(evalfolder, 'rms-error-by-minute.csv'), na = '')
ggsave(file.path(evalfolder, 'rms-error-by-minute.png'), rmserrorsplot, width = 10, height = 5)
