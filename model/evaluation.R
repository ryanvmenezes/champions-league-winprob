library(here)
library(tidyverse)

this.version = 'v2'

source(here('model', 'utils.R'))

predictions = tribble(
  ~version, ~predpath,
  'v1', 'model/v1/predictions.rds',
  'v2.1', 'model/v2/predictions21.rds',
  'v2.2', 'model/v2/predictions22.rds'
) %>% 
  mutate(
    predictions = map(predpath, read_rds),
    ll = map(predictions, calculate.ll.by.minute),
    rms = map(predictions, calculate.rms.errors.by.minute)
  )

predictions

predictions %>% 
  select(version, ll) %>% 
  unnest(c(ll)) %>% 
  filter(predset == 'predictions') %>% 
  select(-predset) %>% 
  pivot_wider(names_from = 'version', values_from = 'loglik') %>% 
  mutate(diff2 = v2.2 - v1) %>% 
  ggplot(aes(minuteclean, diff2)) +
  geom_vline(xintercept = 170, color = 'red') +
  geom_bar(stat = 'identity')

predictions %>% 
  select(version, ll) %>% 
  unnest(c(ll)) %>% 
  filter(predset == 'predictions') %>% 
  ggplot(aes(minuteclean, loglik, color = version)) +
  geom_line() +
  geom_point() +
  scale_x_continuous(
    # limits = c(170, 190),
    breaks = c(0,45,90,135,180,195,210)
  ) +
  theme_minimal()

predictions %>% 
  select(version, rms) %>% 
  unnest(c(rms)) %>% 
  filter(predset == 'predictions') %>% 
  ggplot(aes(minuteclean, rmserror, color = version)) +
  geom_line() +
  # geom_point() +
  scale_x_continuous(
    # limits = c(170, 190),
    breaks = c(0,45,90,135,180,195,210)
  ) +
  theme_minimal()

# predictions = read_rds(here('model', this.version, 'predictions.rds'))

# predictions

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
