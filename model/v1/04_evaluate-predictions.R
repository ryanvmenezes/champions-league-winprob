library(here)
library(tidyverse)

summaries = read_rds(here('data', 'summary.rds'))

summaries

predictions = read_rds(here('model', 'v1', 'predictions.rds'))

predictions

# log likelihoods ---------------------------------------------------------

likelihoods = predictions %>% 
  select(season, stagecode, tieid, t1win, minuteclean, predictedprobt1) %>% 
  mutate(
    likelihood = case_when(
      t1win == FALSE ~ 1 - predictedprobt1,
      t1win == TRUE ~ predictedprobt1
    )
  )

llbytie = likelihoods %>%
  group_by(season, stagecode, tieid) %>%
  summarise(loglik = log(prod(likelihood, na.rm = TRUE))) %>%
  arrange(loglik) %>% 
  ungroup() %>% 
  left_join(summaries) %>% 
  select(season, stagecode, tieid, team1, team2, winner, aggscore, loglik)

llbytie

llbyminute = likelihoods %>% 
  mutate(predset = case_when(season == 2020 ~ 'predictions', TRUE ~ 'training')) %>% 
  group_by(predset, minuteclean) %>%
  summarise(loglik = log(prod(likelihood, na.rm = TRUE))) %>% 
  ungroup()

llbyminute

llbyminuteplot = llbyminute %>% 
  ggplot(aes(minuteclean, loglik, color = predset)) +
  geom_line() +
  theme_minimal()

llbyminuteplot

evalfolder = here('model', 'v1', 'evaluation')

llbytie %>% write_csv(file.path(evalfolder, 'loglik-by-tie.csv'), na = '')
llbyminute %>% write_csv(file.path(evalfolder, 'loglik-by-minute.csv'), na = '')
ggsave(file.path(evalfolder, 'loglik-by-minute.png'), llbyminuteplot)

# errors ------------------------------------------------------------------

errors = predictions %>% 
  select(season, stagecode, tieid, t1win, minuteclean, predictedprobt1) %>% 
  mutate(
    error = as.numeric(t1win) - predictedprobt1,
    sqerror = error ^ 2
  )

rmserrors = errors %>% 
  mutate(predset = case_when(season == 2020 ~ 'predictions', TRUE ~ 'training')) %>% 
  group_by(predset, minuteclean) %>%
  summarise(rmserror = sqrt(mean(sqerror)))

rmserrorsplot = rmserrors %>% 
  ggplot(aes(minuteclean, rmserror, color = predset)) +
  geom_line() +
  theme_minimal()

rmserrorsplot

rmserrors %>% write_csv(file.path(evalfolder, 'rms-error-by-minute.csv'), na = '')
ggsave(file.path(evalfolder, 'rms-error-by-minute.png'), rmserrorsplot)
