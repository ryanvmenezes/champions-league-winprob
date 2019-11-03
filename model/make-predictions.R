library(here)
library(locfit)
library(tidyverse)

minmatrix = read_rds(here('data-get', 'assemble', 'minute-matrix.rds'))

minmatrix

model = read_rds(here('model', 'final-model.rds'))

model

summary(model)

summaries = read_csv(here('data-get', 'assemble', 'matrix-leg-summary.csv'))

summaries
summaries %>% filter(tieid == 'a73408a7|f1e85b1e')

# prediction matrix -------------------------------------------------------

predmatrix = minmatrix %>%
  mutate(
    probh1 = replace_na(probh1, 0.33),
    probd1 = replace_na(probd1, 0.33),
    proba1 = replace_na(proba1, 0.33)
  ) %>% 
  mutate(predictedprobt1 = predict(model, newdata = ., type = 'response'))

predmatrix

predmatrixbytie = predmatrix %>% 
  group_by(season, stagecode, tieid) %>% 
  nest() %>% 
  right_join(summaries)

predmatrixbytie


# log likelihood calc -----------------------------------------------------

likelihoods = predmatrix %>% 
  mutate(
    likelihood = case_when(
      t1win == FALSE ~ 1 - predictedprobt1,
      t1win == TRUE ~ predictedprobt1
    )
  )

# likelihoods %>% 
#   filter(season == 2020 & stagecode == 'el-0q-1fqr' & tieid == '6777e16d|8ab497d5') %>%
#   View()
#   pull(likelihood) %>% 
#   prod() %>% 
#   log()


llbytie = likelihoods %>%
  group_by(season, stagecode, tieid) %>%
  summarise(loglik = log(prod(likelihood, na.rm = TRUE))) %>%
  arrange(loglik) %>% 
  left_join(summaries)

llbytie

llbytie %>% select(season:loglik)

predmatrixbytie %>% 
  filter(season == 2020 & stagecode == 'el-0q-1fqr' & tieid == '6777e16d|8ab497d5') %>%
  select(data) %>% 
  unnest(cols = c(data)) %>% 
  ungroup() %>%
  ggplot(aes(minuteclean, predictedprobt1)) +
  theme_minimal() +
  geom_line() +
  geom_point(data = . %>% filter(str_detect(eventtype, 'goal')), aes(minuteclean, predictedprobt1)) +
  geom_point(data = . %>% filter(str_detect(eventtype, 'red')), aes(minuteclean, predictedprobt1), color = 'red') +
  scale_x_continuous(
    breaks = c(0, 45, 90, 135, 180, 210),
    labels = c('g1 start','g1 half','g1 end\ng2 start','g2 half','g2 end\net start','et end')
  ) +
  scale_y_continuous(limits = c(0,1))


llbyminute20 = likelihoods %>% 
  filter(season == 2020) %>% 
  group_by(minuteclean) %>% 
  summarise(loglik = log(prod(likelihood, na.rm = TRUE)))

llbyminute20 %>% 
  ggplot(aes(minuteclean, loglik)) +
  theme_minimal() +
  geom_line() +
  scale_x_continuous(
    breaks = c(0, 45, 90, 135, 180, 210),
    labels = c('g1 start','g1 half','g1 end\ng2 start','g2 half','g2 end\net start','et end')
  )


llbyminute = likelihoods %>% 
  filter(season < 2020) %>% 
  group_by(minuteclean) %>% 
  summarise(loglik = log(prod(likelihood, na.rm = TRUE)))

llbyminute %>% 
  ggplot(aes(minuteclean, loglik)) +
  theme_minimal() +
  geom_line() +
  geom_line(data = llbyminute20) +
  scale_x_continuous(
    breaks = c(0, 45, 90, 135, 180, 210),
    labels = c('g1 start','g1 half','g1 end\ng2 start','g2 half','g2 end\net start','et end')
  )

predictions %>%
  write_rds(here('model', 'min-matrix-trim.rds'), compress = 'gz')


likelihoods %>% 
  filter(minuteclean == 1) %>% 
  arrange(likelihood) %>% 
  select(season:tieid, likelihood)


# plots -------------------------------------------------------------------

predmatrixbytie

winprobplot = function(t1, t2, aggscore, result, df) {
  ggplot(data = df, aes(minuteclean, predictedprobt1)) +
    theme_minimal() +
    geom_line() +
    geom_point(data = . %>% filter(str_detect(eventtype, 'goal')), aes(minuteclean, predictedprobt1)) +
    geom_point(data = . %>% filter(str_detect(eventtype, 'red')), aes(minuteclean, predictedprobt1), color = 'red') +
    scale_x_continuous(
      breaks = c(0, 45, 90, 135, 180, 210),
      labels = c('g1 start','g1 half','g1 end\ng2 start','g2 half','g2 end\net start','et end')
    ) +
    scale_y_continuous(limits = c(0,1)) +
    ggtitle(str_c(t1, aggscore, t2, sep = ' '))
}

plots = predmatrixbytie %>% 
  mutate(plot = pmap(list(team1, team2, aggscore, result, data), winprobplot)) %>% 
  select(season, stagecode, tieid, plot)

plots %>%
  filter(tieid == 'a73408a7|f1e85b1e') %>% 
  `[[`('plot')


likelihoods %>% 
  filter(!aet) %>% 
  filter(minuteclean == 180) %>% 
  arrange(likelihood) %>% 
  select(season:tieid, likelihood) %>% 
  head(10) %>% 
  left_join(plots) %>% 
  `[[`('plot')


# plot_winprob = function(slug) {
#   pieces = str_split(slug, pattern = '\\|')
#   y = pieces[[1]][1]
#   r = pieces[[1]][2]
#   t = pieces[[1]][3]
#   t1 = str_split(t, pattern='-')[[1]][1]
#   t2 = str_split(t, pattern='-')[[1]][2]
#   t1full = teamnames %>% filter(teamcode == t1) %>% pull(fullteam)
#   t2full = teamnames %>% filter(teamcode == t2) %>% pull(fullteam)
#   t1code = teamnames %>% filter(teamcode == t1) %>% pull(shortcode)
#   t2code = teamnames %>% filter(teamcode == t2) %>% pull(shortcode)
#   result = results %>% 
#     filter(season == y) %>% 
#     filter(round == r) %>% 
#     filter(tie == t) %>% 
#     pull(result)
#   title = str_c(
#     result,'\n',
#     y, ' ',
#     case_when(
#       r == 'first' ~ 'Round of 16',
#       r == 'qtr' ~ 'Quarterfinal',
#       r == 'semi' ~ 'Semifinal',
#       TRUE ~ ''
#     )
#   )
#   winprob %>% 
#     filter(season == y) %>% 
#     filter(round == r) %>% 
#     filter(tie == t) %>% 
#     # gather(key = winprobmodel, value = winprob, neutral, pregameodds, pregameodds2, pregameodds3) %>% 
#     # ggplot(aes(made_minute, winprob, color=winprobmodel)) +
#     ggplot(aes(made_minute, pregameodds3)) +
#     geom_line() +
#     scale_y_continuous(
#       limits = c(0,1),
#       breaks = c(0.0,0.25,0.5,0.75,1.0),
#       labels = c(
#         str_c(t2code, '\n100%'),
#         str_c(t2code, '\n75%'),
#         '50%',
#         str_c(t1code, '\n75%'),
#         str_c(t1code, '\n100%')
#       )
#     ) +
#     scale_x_continuous(
#       breaks = c(0, 46, 92, 138, 184),
#       labels = c('Gm. 1 start','Gm. 1 half','Gm. 1 end\nGm. 2 start','Gm. 2 half','End')
#     ) +
#     theme_minimal() +
#     annotate('text', x = 1, y = 0.975, label = str_c('At ', t1full), size = 3, hjust = 0) +
#     annotate('text', x = 93, y = 0.975, label = str_c('At ', t2full), size = 3, hjust = 0) +
#     xlab("Minutes left") +
#     ylab("") +
#     ggtitle(title)
# }