library(here)
library(tidyverse)

ties = read_csv(here('data-get', 'fbref', 'cleaned', 'two-legged-ties.csv'))
ties

results = ties %>% 
  separate(aggscore, into = c('aggscore1','aggscore2'), remove = FALSE) %>% 
  mutate(
    t1win = (winner == team1) %>% as.numeric(),
    agr = str_detect(str_to_lower(result), 'away goals') %>% as.numeric(),
    aet = str_detect(str_to_lower(result), 'extra time') %>% as.numeric(),
    pk = str_detect(str_to_lower(result), 'penalty') %>% as.numeric()
  ) %>% 
  mutate(
    # fix an error in the data
    agr = case_when(
      (aggscore1 == aggscore2) & (!pk) ~ TRUE,
      TRUE ~ agr
    )
  )

results

# integrity checks         
results %>% filter(score1 == score2) %>% filter(!pk) %>% nrow()
results %>% filter(score1 == score2) %>% filter(!aet) %>% nrow()
results %>% filter(aggscore1 == aggscore2) %>% filter(!pk) %>% filter(!agr) %>% nrow()
results %>% filter(as.numeric(aggscore1) > as.numeric(aggscore2)) %>% filter(winnerid != teamid1) %>% nrow()
results %>% filter(as.numeric(aggscore2) > as.numeric(aggscore1)) %>% filter(winnerid != teamid2) %>% nrow()

events = read_csv(here('data-get', 'fbref', 'cleaned', 'match-events.csv'))
events

events %>% count(eventtype)


eventscleaned = events %>% 
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
  left_join(
    results %>%
      select(szn, stagecode, teamid1, teamid2, t1win, agr, aet, pk),
    by = c("szn", "stagecode", "teamid1", "teamid2")
  ) %>% 
  group_by(szn, stagecode, teamid1, teamid2, t1win, agr, aet, pk) %>% 
  nest()

eventscleaned

expandminutes = function(data, aet = FALSE) {
  minutemax = if_else(aet, 210, 180)
  
  data %>% 
    right_join(tibble(minuteclean = 1:minutemax), by = 'minuteclean') %>% 
    mutate(
      leg = map_dbl(minuteclean, ~if_else(.x <= 90, 1, 2)),
      goalst1 = replace_na(goalt1, 0) %>% cumsum(),
      goalst2 = replace_na(goalt2, 0) %>% cumsum(),
      awaygoalst1 = replace_na(awaygoalt1, 0) %>% cumsum(),
      awaygoalst2 = replace_na(awaygoalt2, 0) %>% cumsum()
    ) %>% 
    group_by(leg) %>% 
    mutate(
      redcardst1 = replace_na(redcardt1, 0) %>% cumsum(),
      redcardst2 = replace_na(redcardt2, 0) %>% cumsum()
    ) %>% 
    select(minuteclean, leg, goalst1:redcardst2)
}

eventscleaned = eventscleaned %>% 
  mutate(minutematrix = map2(data, aet, expandminutes))

eventscleaned %>% filter(aet) %>% head(1) %>% pull(minutematrix) %>% `[[`(1) %>% tail()

eventscleaned[764,]
eventscleaned$data[[764]] %>% arrange(minuteclean)
eventscleaned$data[[764]] %>% expandminutes() %>% tail()
