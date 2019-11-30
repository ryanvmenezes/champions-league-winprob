library(here)
library(tidyverse)

summaries = read_rds(here('data', 'summary.rds'))

summaries

predictions = read_rds(here('model', 'predictions.rds'))

predictions

fullpredictions = summaries %>% 
  right_join(
    predictions %>% 
      group_by(season, stagecode, tieid, t1win) %>% 
      mutate(ag = abs(awaygoalst1diff - lag(awaygoalst1diff)) == 1) %>% 
      nest()
  )

fullpredictions

winprobplot = function(t1, t2, result, df, szn, stage) {
  ggplot(data = df, aes(minuteclean, predictedprobt1)) +
    geom_vline(xintercept = 90, linetype = 'dashed', alpha = 0.5) +
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
      labels = c('0 ', '25 ', '50 ', '75 ', '100%')
    ) +
    ggtitle(str_c(result, '\n', szn, ' ', stage)) +
    ylab(str_c(t1, ' win probability')) +
    xlab('') +
    theme_minimal() +
    theme(panel.grid.minor = element_blank())
}

plots = fullpredictions %>% 
  mutate(plot = pmap(list(team1, team2, result, data, season, stagecode), winprobplot)) %>% 
  select(-data)

plots

plots %>% write_rds(here('model', 'plots.rds'), compress = 'gz')

plots %>%
  separate(stagecode, into = c('comp', 'round'), extra = 'merge') %>% 
  select(season, comp, round, team1, team2, plot) %>% 
  pwalk(
    function(season, comp, round, team1, team2, plot) {
      compfolder = file.path(here('model', 'plots'), comp)
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
