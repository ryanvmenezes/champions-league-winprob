library(here)
library(tidyverse)

CURRENT_VERSION = 'v1'

summaries = read_rds(here('data', 'summary.rds'))

summaries

predictions = read_rds(here('model', 'predictions', CURRENT_VERSION, 'predictions.rds'))

predictions

fullpredictions = summaries %>% 
  right_join(
    predictions %>% 
      group_by(season, stagecode, tieid, t1win) %>% 
      mutate(
        ag = abs(awaygoalst1diff - lag(awaygoalst1diff)) == 1,
        ag = replace_na(ag, FALSE),
        ag = case_when((minuteclean == 1) & (abs(awaygoalst1diff) == 1) ~ TRUE, TRUE ~ ag)
      ) %>% 
      nest()
  )

fullpredictions

winprobplot = function(t1, t2, result, df, szn, stage, aet) {
  initprob = df %>%
    filter(minuteclean == 1) %>% 
    pull(predictedprobt1) %>% 
    `[`(1)
  
  initteamprob = case_when(
    initprob < 0.5 ~ str_c(t2, ' ', round((1 - initprob) * 100, digits = 1), '%'),
    TRUE ~ str_c(t1, ' ', round(initprob * 100, digits = 1), '%')
  )
  
  inittitle = str_c('Initial: ', initteamprob)
  
  t1short = iconv(t1, from = 'UTF-8', to = 'ASCII//TRANSLIT') %>%
    str_replace_all(' ', '') %>%
    str_replace_all("[^[:alnum:]]", "") %>% 
    str_sub(end = 3) %>%
    str_to_upper()
  t2short = iconv(t2, from = 'UTF-8', to = 'ASCII//TRANSLIT') %>%
    str_replace_all(' ', '') %>% 
    str_replace_all("[^[:alnum:]]", "") %>% 
    str_sub(end = 3) %>%
    str_to_upper()
  
  plot = ggplot(data = df, aes(minuteclean, predictedprobt1)) +
    geom_vline(xintercept = 90, linetype = 'dashed', alpha = 0.5) +
    annotate('text', label = str_c('at ', t1, sep = ''), x = 45, y = 0.5, size = 5, alpha = 0.2)
  
  if (aet) {
    plot = plot +
      geom_vline(xintercept = 180, linetype = 'dashed', alpha = 0.5) +
      annotate('text', label = str_c('at ', t2, sep = ''), x = 150, y = 0.5, size = 5, alpha = 0.2)
  } else {
    plot = plot +
      annotate('text', label = str_c('at ', t2, sep = ''), x = 135, y = 0.5, size = 5, alpha = 0.2)
  }
  
  plot = plot +
    geom_line() +
    geom_point(
      data = . %>%
        filter(ag),
      aes(minuteclean, predictedprobt1),
      color = 'pink',
      size = 3
    ) +
    geom_point(
      data = . %>%
        filter(str_detect(eventtype, 'goal')),
      aes(minuteclean, predictedprobt1),
      color = 'blue'
    ) +
    geom_point(
      data = . %>%
        filter(str_detect(eventtype, 'red')),
      aes(minuteclean, predictedprobt1),
      fill = 'red',
      shape = 22
    ) +
    scale_x_continuous(
      breaks = c(0, 45, 90, 135, 180, 210),
      labels = c('G1 Start','G1 Half','G1 End\nG2 Start','G2 Half','G2 End\nET Start','ET End')
    ) +
    scale_y_continuous(
      limits = c(0,1),
      breaks = c(0, 0.25, 0.5, 0.75, 1),
      labels = c(str_c('100%\n', t2short), '75 ', '50 ', '75 ', str_c(t1short, '\n100%'))
    ) +
    ggtitle(str_c(result, '\n', inittitle, '\n', szn, ' ', stage)) +
    ylab('') +
    xlab('') +
    theme_minimal() +
    theme(panel.grid.minor = element_blank())
  
  return(plot)
}

plots = fullpredictions %>%
  mutate(plot = pmap(list(team1, team2, result, data, season, stagecode, aet), winprobplot)) %>% 
  select(-data)

beepr::beep()

plots

plots %>% write_rds(here('model', 'plots', CURRENT_VERSION, 'plots.rds'), compress = 'gz')

beepr::beep()

plots %>%
  separate(stagecode, into = c('comp', 'round'), extra = 'merge') %>% 
  select(season, comp, round, team1, team2, plot) %>% 
  pwalk(
    function(season, comp, round, team1, team2, plot) {
      modelversionfolder = file.path(here('model', 'plots'), str_c('v', CURRENT_VERSION))
      if(!dir.exists(modelversionfolder)) { dir.create(modelversionfolder) }
      compfolder = file.path(modelversionfolder, comp)
      if(!dir.exists(compfolder)) { dir.create(compfolder) }
      yearfolder = file.path(compfolder, season)
      if(!dir.exists(yearfolder)) { dir.create(yearfolder) }
      roundfolder = file.path(yearfolder, round)
      if(!dir.exists(roundfolder)) { dir.create(roundfolder) }
      fpath = str_c(team1, '-', team2, '.png')
      fpath = str_replace_all(fpath, '/', '')
      ggsave(
        filename = file.path(roundfolder, fpath),
        plot = plot,
        device = 'png',
        width = 10,
        height = 5,
        units = 'in'
        # dpi = 'retina'
      )
    }
  )

beepr::beep()
