library(here)
library(tidyverse)

source(here('model', 'utils.R'))

preds.folder = here('model', 'predictions')

predictions = tibble(version = list.files(preds.folder)) %>% 
  filter(str_ends(version, 'rds')) %>% 
  mutate(
    fpath = glue::glue('{preds.folder}/{version}'),
    preds = map(fpath, read_rds),
    version = str_replace(version, '.rds', '')
  ) %>% 
  select(-fpath) %>% 
  mutate(
    loglik = map(preds, calculate.ll.by.minute),
    rms = map(preds, calculate.rms.errors.by.minute)
  )

predictions

compare.loglik = predictions %>% 
  select(version, loglik) %>% 
  unnest(c(loglik)) %>% 
  filter(predset == 'predictions')

compare.loglik

loglik.winner.by.minute = compare.loglik %>% 
  group_by(minuteclean) %>% 
  filter(loglik == min(loglik)) %>% 
  arrange(minuteclean)

loglik.winner.by.minute

plot.compare.ll = compare.loglik %>%
  ggplot(aes(minuteclean, loglik, color = version)) +
  geom_line() +
  # geom_point() +
  scale_x_continuous(
    breaks = c(0,45,90,135,180,195,210)
  ) +
  theme_minimal()

plot.compare.ll

compare.rms = predictions %>% 
  select(version, rms) %>% 
  unnest(c(rms)) %>% 
  filter(predset == 'predictions')

compare.rms

rms.winner.by.minute = compare.rms %>% 
  group_by(minuteclean) %>% 
  filter(rmserror == min(rmserror)) %>% 
  arrange(minuteclean)

rms.winner.by.minute

plot.compare.rms = compare.rms %>% 
  ggplot(aes(minuteclean, rmserror, color = version)) +
  geom_line() +
  scale_x_continuous(
    breaks = c(0,45,90,135,180,195,210)
  ) +
  theme_minimal()

plot.compare.rms

loglik.winner.by.minute %>% write_csv('model/evaluation/log-lik-top-model-by-minute.csv', na = '')
rms.winner.by.minute %>% write_csv('model/evaluation/rms-top-model-by-minute.csv', na = '')

ggsave(plot = plot.compare.ll, filename = 'model/evaluation/compare-log-lik.png', width = 10, height = 5)
ggsave(plot = plot.compare.rms, filename = 'model/evaluation/compare-rms.png', width = 10, height = 5)

llbytie = predictions %>% 
  mutate(tie.ll = map(preds, calculate.ll.by.tie)) %>% 
  select(version, tie.ll) %>% 
  unnest(c(tie.ll)) %>% 
  pivot_wider(names_from = 'version', values_from = 'loglik') %>% 
  arrange(v2.2.1)

llbytie %>% write_csv('model/evaluation/log-lik-by-tie.csv', na = '')
