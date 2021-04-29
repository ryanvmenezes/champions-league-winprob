library(here)
library(tidyverse)
library(furrr)

summaries = read_csv(here('data-get', 'assemble', 'summary', 'summary.csv'))

summaries

events = read_csv(here('data-get', 'fbref', 'processed', 'match-events.csv'))

events

events %>% count(eventtype)

eventscleaned = events %>% 
  mutate(szn = as.numeric(str_sub(szn, end = 4)) + 1) %>% 
  rename(season = szn) %>%
  right_join(
    summaries %>% 
      select(season, stagecode, tieid, aet, has_events, in_progress, in_progress_halfway) %>% 
      filter(has_events)
  ) %>% 
  mutate(
    goalt1 = (str_detect(eventtype, 'goal') & ((leg == 1 & team == 1) | (leg == 2 & team == 2))) %>% as.numeric(),
    goalt2 = (str_detect(eventtype, 'goal') & ((leg == 1 & team == 2) | (leg == 2 & team == 1))) %>% as.numeric(),
    awaygoalt1 = (goalt1 == 1 & leg == 2) %>% as.numeric(),
    awaygoalt2 = (goalt2 == 1 & leg == 1) %>% as.numeric(),
    redcardt1 = (str_detect(eventtype, 'red_card') & ((leg == 1 & team == 1) | (leg == 2 & team == 2))) %>% as.numeric(),
    redcardt2 = (str_detect(eventtype, 'red_card') & ((leg == 1 & team == 2) | (leg == 2 & team == 1))) %>% as.numeric(),
    minuteclean = minute %>% str_replace_all('\\+\\d+', '') %>% as.integer(),
    minuteclean = minuteclean + if_else(leg == 2, 90, 0),
    player = case_when(str_detect(eventtype, 'own_goal') ~ str_c(player, ' (OG)'), TRUE ~ player)
  )

eventscleaned

eventsnested = eventscleaned %>% 
  group_by(season, stagecode, tieid, aet, in_progress, in_progress_halfway, has_events) %>% 
  nest()

eventsnested

expandminutes = function(data, aet = FALSE, in_progress = FALSE, in_progress_halfway = FALSE) {
  minutemax = case_when(
    aet ~ 210,
    in_progress_halfway ~ 90,
    in_progress ~ 0,
    TRUE ~ 180
  )
  
  df = data %>% 
    right_join(tibble(minuteclean = 0:minutemax), by = 'minuteclean') %>% 
    drop_na(minuteclean) %>% 
    arrange(minuteclean, minute) %>% 
    mutate(
      minuterown = row_number(),
      leg = map_dbl(minuteclean, ~if_else(.x <= 90, 1, 2)),
      goalst1 = replace_na(goalt1, 0) %>% cumsum(),
      goalst2 = replace_na(goalt2, 0) %>% cumsum(),
      goalst1diff = goalst1 - goalst2,
      awaygoalst1 = replace_na(awaygoalt1, 0) %>% cumsum(),
      awaygoalst2 = replace_na(awaygoalt2, 0) %>% cumsum(),
      awaygoalst1diff = awaygoalst1 - awaygoalst2
    ) %>% 
    group_by(leg) %>% 
    mutate(
      redcardst1 = replace_na(redcardt1, 0) %>% cumsum(),
      redcardst2 = replace_na(redcardt2, 0) %>% cumsum(),
      redcardst1diff = redcardst1 - redcardst2
    ) %>% 
    select(
      minuteclean, minuterown, leg, goalst1:redcardst1diff,
      player, playerid, eventtype, minute, team
    )
  
  return(df)
}

plan(multicore)
options('future.fork.enable' = TRUE)

eventsnested = eventsnested %>% 
  mutate(minutematrix = future_pmap(list(data, aet, in_progress, in_progress_halfway), expandminutes, .progress = TRUE))

eventsnested

eventsmatrix = eventsnested %>% 
  select(-data) %>% 
  unnest(minutematrix) %>% 
  ungroup()

eventsmatrix

eventsmatrix %>% write_csv(here('data-get', 'assemble', 'events', 'events.csv'), na = '')
eventsmatrix %>% write_rds(here('data', 'events.rds'), compress = 'gz')
