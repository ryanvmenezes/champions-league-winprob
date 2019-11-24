library(here)
library(tidyverse)

# ties = read_csv(here('data-get', 'fbref', 'processed', 'two-legged-ties.csv'))
# 
# ties

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
      select(season, stagecode, tieid, aet, has_events) %>% 
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
  ) %>% 
  group_by(season, stagecode, tieid, aet, has_events) %>% 
  nest() #@%>% 
  # right_join(
  #   summaries %>% 
  #     select(season, stagecode, tieid, aet, has_events) %>% 
  #     filter(has_events)
  # ) %>% 
  # mutate(
  #   data = case_when(
  #     is.na(data) ~ tibble(
  #       teamid1 = character(),
  #       teamid2 = character(),
  #       leg = numeric(),
  #       score = character(),
  #       player = character(),
  #       playerid = character(),
  #       eventtype = character(),
  #       minute = character(),
  #       team = numeric(),
  #       goalt1 = numeric(),
  #       goalt2 = numeric(),
  #       awaygoalt1 = numeric(),
  #       awaygoalt2 = numeric(),
  #       redcardt1 = numeric(),
  #       redcardt2 = numeric(),
  #       minuteclean = numeric()
  #     ),
  #     TRUE ~ data
  #   )
  # )

eventscleaned

eventscleaned %>% filter(is.na(data))

eventscleaned %>% 
  filter(
    (season == 2019 & tieid == '7de37644|aa065002') |
      (season == 2019 & tieid == '18050b20|922493f3') |
      (season == 2020 & tieid == '1eebf7c3|8cac5dfa')
  ) %>% 
  pull(data)

names(eventscleaned$data[[1]])

expandminutes = function(data, aet = FALSE) {
  minutemax = if_else(aet, 210, 180)
  
  data %>% 
    right_join(tibble(minuteclean = 1:minutemax), by = 'minuteclean') %>% 
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
      minuteclean, minuterown, leg, goalst1:redcardst1diff, player, playerid, eventtype, minute, team
    )
}

summaries %>% 
  select(season, stagecode, tieid, aet, has_events) %>% 
  filter(has_events) %>% 
  left_join(eventscleaned) %>% 
  filter(is.na(data)) %>% 
  left_join(summaries) %>% 
  select(-data) %>% 
  View()



eventscleaned %>% 
  left_join(summaries) %>% 
  filter(aggscore == '0–0') %>% 
  pull(data) %>% 
  `[[`(2)
