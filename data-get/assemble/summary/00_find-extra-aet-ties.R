# sometimes fbref's result doesn't say "extra time" in it
# this finds the ties where the final aggregate score does not equal the score after 180 minutes
# if the result doesn't say "extra time" we need to mark that

library(here)
library(tidyverse)

ties = read_csv(here('data-get', 'fbref', 'processed', 'two-legged-ties.csv'))

ties

events = read_csv(here('data-get', 'fbref', 'processed', 'match-events.csv'))

events

invalidties = read_csv(here('data-get', 'assemble', 'summary', 'invalid-ties.csv'))

invalidties

eventscleaned = events %>%
  mutate(szn = as.numeric(str_sub(szn, end = 4)) + 1) %>%
  rename(season = szn) %>%
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

event.goal.totals.180 = eventscleaned %>%
  group_by(season, stagecode, tieid) %>%
  filter(minuteclean <= 180) %>%
  summarise(
    goalt1.tie = sum(goalt1, na.rm = TRUE),
    goalt2.tie = sum(goalt2, na.rm = TRUE)
  )

event.goal.totals.180

extra.aet.ties = ties %>%
  mutate(szn = as.numeric(str_sub(szn, end = 4)) + 1) %>%
  rename(season = szn) %>%
  separate(aggscore, into = c('goalt1.tie', 'goalt2.tie'), remove = FALSE) %>%
  mutate(
    goalt1.tie = as.numeric(goalt1.tie),
    goalt2.tie = as.numeric(goalt2.tie)
  ) %>%
  anti_join(event.goal.totals.180) %>%
  left_join(
    event.goal.totals.180 %>%
      rename(goalt1.tie.180 = goalt1.tie, goalt2.tie.180 = goalt2.tie)
  ) %>%
  filter(!str_detect(str_to_lower(result), 'extra time')) %>%
  filter(!is.na(winner)) %>%
  anti_join(invalidties)

extra.aet.ties

extra.aet.ties %>% write_csv(here('data-get', 'assemble', 'summary', 'extra-aet-ties.csv'))
