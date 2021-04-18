# winprobplot.simple = function(match.data) {
#   match.data %>% 
#     ggplot(aes(minuteclean, predictedprobt1)) +
#     geom_line() +
#     # geom_point(
#     #   data = . %>% filter(ag),
#     #   aes(minuteclean, predictedprobt1),
#     #   color = 'pink',
#     #   size = 3
#     # ) +
#     # geom_point(
#     #   data = . %>% filter(str_detect(eventtype, 'goal')),
#     #   aes(minuteclean, predictedprobt1),
#     #   color = 'blue'
#     # ) +
#     # geom_point(
#     #   data = . %>% filter(str_detect(eventtype, 'red')),
#     #   aes(minuteclean, predictedprobt1),
#     #   fill = 'red',
#     #   shape = 22
#     # ) +
#     scale_x_continuous(
#       breaks = c(0, 45, 90, 135, 180, 195, 210),
#     ) +
#     scale_y_continuous(
#       limits = c(0,1),
#       breaks = c(0, 0.25, 0.5, 0.75, 1)
#     ) +
#     theme_minimal()
# }

winprobplot = function(t1, t2, result, df, szn, stage, aet) {
  initprob = df %>%
    filter(minuteclean == 0) %>% 
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
    # geom_point(
    #   data = . %>% filter(ag),
    #   aes(minuteclean, predictedprobt1),
    #   color = 'pink',
    #   size = 3
    # ) +
    # geom_point(
    #   data = . %>% filter(str_detect(eventtype, 'goal')),
    #   aes(minuteclean, predictedprobt1),
    #   color = 'blue'
    # ) +
    # geom_point(
    #   data = . %>% filter(str_detect(eventtype, 'red')),
    #   aes(minuteclean, predictedprobt1),
    #   fill = 'red',
    #   shape = 22
    # ) +
    scale_x_continuous(
      limits = c(0, if_else(aet, 210, 180)),
      breaks = c(0, 45, 90, 135, 180, 195, 210),
      labels = c('G1 Start', 'G1 Half', 'G1 End\nG2 Start', 'G2 Half', if_else(aet, 'G2 End\nET Start', 'G2 End'), '', 'ET End')
    ) +
    scale_y_continuous(
      limits = c(0,1),
      breaks = c(0, 0.25, 0.5, 0.75, 1),
      labels = c(str_c('100%\n', t2short), '75 ', '50 ', '75 ', str_c(t1short, '\n100%'))
    ) +
    ggtitle(
      str_c(
        if_else(
          is.na(result),
          str_c(t1, '-', t2, ' in progress'),
          result
        ),
        '\n', inittitle, '\n', szn, ' ', stage
      )
    ) +
    ylab('') +
    xlab('') +
    theme_minimal() +
    theme(panel.grid.minor = element_blank())
  
  return(plot)
}
