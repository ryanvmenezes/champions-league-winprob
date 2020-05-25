source('utils.R')

test.season.cutoff = 2020

summaries = read_rds(here('data', 'summary.rds'))
odds = read_rds(here('data', 'odds.rds'))
events = read_rds(here('data', 'events.rds'))

# matrix of training data
all.data = summaries %>% 
  filter(has_events) %>% 
  filter(!has_invalid_match) %>% 
  left_join(events, by = c("season", "stagecode", "tieid", "aet", "has_events", "in_progress")) %>% 
  left_join(odds, by = c("season", "stagecode", "tieid")) %>% 
  select(
    season, stagecode, tieid,
    t1win,
    probh1, probd1, proba1,
    minuteclean, minuterown,
    goalst1diff, awaygoalst1diff, redcardst1diff,
    player, playerid, eventtype
  ) %>% 
  mutate(
    probh1 = replace_na(probh1, 0.33),
    probd1 = replace_na(probd1, 0.33),
    proba1 = replace_na(proba1, 0.33)
  ) %>% 
  # add logical flag to indicate away goal (for plotting)
  group_by(season, stagecode, tieid, t1win) %>% 
  mutate(
    ag = abs(awaygoalst1diff - lag(awaygoalst1diff)) == 1,
    ag = replace_na(ag, FALSE),
    ag = case_when((minuteclean == 1) & (abs(awaygoalst1diff) == 1) ~ TRUE, TRUE ~ ag)
  ) %>% 
  ungroup()

run.glm = function(data) {
  glm(
    t1win ~ goalst1diff + awaygoalst1diff + redcardst1diff + probh1 + proba1,
    data = data,
    family = 'binomial'
  )
}

# train model on everything but this most recent season
training.data = all.data %>% filter(season < test.season.cutoff)

make.predictions = function(model, data = all.data) {
  data %>% 
    mutate(
      predictedprobt1 = predict(model, newdata = ., type = 'response'),
      likelihood = case_when(
        t1win == FALSE ~ 1 - predictedprobt1,
        t1win == TRUE ~ predictedprobt1
      ),
      error = as.numeric(t1win) - predictedprobt1,
      sqerror = error ^ 2
    )
}

save.predictions = function(predictions, version) {
  predictions %>% 
    write_rds(here('model', 'predictions', glue::glue('{version}.rds')))
  
  predictions %>% 
    write_rds(here('model', 'predictions', glue::glue('{version}.csv')))
}

read.predictions = function(predictions, version) {
  predictions %>% 
    read_rds(here('model', 'predictions', glue::glue('{version}.rds')))
}

winprobplot.simple = function(match.data) {
  match.data %>% 
    ggplot(aes(minuteclean, predictedprobt1)) +
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
      breaks = c(0, 45, 90, 135, 180, 195, 210),
    ) +
    scale_y_continuous(
      limits = c(0,1),
      breaks = c(0, 0.25, 0.5, 0.75, 1)
    ) +
    theme_minimal()
}

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
      limits = c(0, if_else(aet, 210, 180)),
      breaks = c(0, 45, 90, 135, 180, 195, 210),
      labels = c('G1 Start','G1 Half','G1 End\nG2 Start','G2 Half',if_else(aet, 'G2 End\nET Start', 'G2 End'),'','ET End')
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

make.all.plots = function(predictions) {
  summaries %>% 
    right_join(
      predictions %>% 
        group_by(season, stagecode, tieid, t1win) %>% 
        nest()
    ) %>%
    mutate(plot = future_pmap(list(team1, team2, result, data, season, stagecode, aet), winprobplot, .progress = TRUE)) %>% 
    select(-data)
}

export.all.plots = function(plots, plotsfolder) {
  plots %>% 
    separate(stagecode, into = c('comp', 'round'), extra = 'merge') %>% 
    select(comp, season, round) %>%
    distinct() %>% 
    pwalk(
      function(comp, season, round) {
        if (!dir.exists(plotsfolder)) { dir.create(plotsfolder) }
        compfolder = file.path(plotsfolder, comp)
        if(!dir.exists(compfolder)) { dir.create(compfolder) }
        yearfolder = file.path(compfolder, season)
        if(!dir.exists(yearfolder)) { dir.create(yearfolder) }
        roundfolder = file.path(yearfolder, round)
        if(!dir.exists(roundfolder)) { dir.create(roundfolder) }
      }
    )
  
  outplots = plots %>%
    separate(stagecode, into = c('comp', 'round'), extra = 'merge') %>% 
    transmute(
      outpath = pmap_chr(
        list(comp, season, round, team1, team2),
        function(comp, season, round, team1, team2) {
          roundfolder = here('model', this.version, 'plots', comp, season, round)
          fpath = str_c(team1, '-', team2, '.png')
          fpath = str_replace_all(fpath, '/', '')
          outpath = file.path(roundfolder, fpath)
          return (outpath)
        }
      ),
      plot
    )
  
  outplots
  
  null.output = future_map2(
    outplots$outpath,
    outplots$plot,
    function(outpath, plot) {
      ggsave(
        filename = outpath,
        plot = plot,
        device = 'png',
        width = 10,
        height = 5,
        units = 'in'
      )
      
      return (NULL)
    },
    .progress = TRUE
  )
  
  beepr::beep()
}

calculate.ll.by.tie = function(predictions) {
  predictions %>% 
    group_by(season, stagecode, tieid) %>%
    summarise(loglik = log(prod(likelihood, na.rm = TRUE))) %>%
    arrange(loglik) %>% 
    ungroup() %>% 
    left_join(summaries) %>% 
    filter(!is.na(winner)) %>% 
    select(season, stagecode, tieid, team1, team2, winner, aggscore, loglik)
}

calculate.ll.by.minute = function(predictions) {
  predictions %>% 
    mutate(predset = case_when(season == test.season.cutoff ~ 'predictions', TRUE ~ 'training')) %>% 
    group_by(predset, minuteclean) %>%
    summarise(loglik = log(prod(likelihood, na.rm = TRUE))) %>% 
    ungroup()
}

calculate.rms.errors.by.minute = function(predictions) {
  predictions %>% 
    mutate(predset = case_when(season == test.season.cutoff ~ 'predictions', TRUE ~ 'training')) %>% 
    group_by(predset, minuteclean) %>%
    summarise(rmserror = sqrt(mean(sqerror, na.rm = TRUE)))
}

# window of data for each minute
# shrink window toward end

filter.by.minute = function(m) {
  if(m < 170) {
    filtered = training.data %>%
      filter(minuteclean >= m - 10, minuteclean <= m + 10)
  }
  if(m >= 170 & m < 180) {
    filtered = training.data %>%
      filter(minuteclean >= m - 3, minuteclean <= m + 3)
  }
  if(m == 180) {
    filtered = training.data %>%
      filter(minuteclean >= m - 1, minuteclean <= m + 1)
  }
  if(m > 180 & m < 200) {
    filtered = training.data %>%
      filter(minuteclean > 180, minuteclean >= m - 15, minuteclean <= m + 15)
  }
  if(m >= 200 & m < 210) {
    filtered = training.data %>%
      filter(minuteclean > 180, minuteclean >= m - 3, minuteclean <= m + 3)
  }
  if(m == 210) {
    filtered = training.data %>%
      filter(minuteclean > 180, minuteclean >= m - 1, minuteclean <= m + 1)
  }
  return(filtered)
}



