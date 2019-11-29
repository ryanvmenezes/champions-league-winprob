library(here)
library(tidyverse)

summaries = read_csv(here('data-get', 'assemble', 'summary', 'summary.csv'))

summaries

predictions = read_csv(here('data-get', 'model', 'predictions.csv'))

predictions

fullpredictions = summaries %>% 
  right_join(
    predictions %>% 
      group_by(season, stagecode, tieid, t1win) %>% 
      mutate(ag = abs(awaygoalst1diff - lag(awaygoalst1diff)) == 1) %>% 
      nest()
  )

fullpredictions

winprobplot = function(t1, t2, result, df) {
  ggplot(data = df, aes(minuteclean, predictedprobt1)) +
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
    scale_y_continuous(limits = c(0,1)) +
    ggtitle(result) +
    ylab(str_c(t1, ' win probability')) +
    xlab('') +
    theme_minimal()
}

plots = fullpredictions %>% 
  mutate(plot = pmap(list(team1, team2, result, data), winprobplot))

plots

plots %>%
  filter(tieid == '86b7acd2|ec560e72') %>% 
  pull(plot)
