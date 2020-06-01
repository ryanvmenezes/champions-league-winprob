library(glue)
library(here)
library(tidyverse)

source(here('model', 'utils.R'))

model.version = 'v2.2'

predictions = read.predictions(model.version)

predictions

ll.by.tie = predictions %>% 
  group_by(season, stagecode, tieid) %>%
  summarise(loglik = log(prod(likelihood, na.rm = TRUE))) %>%
  arrange(loglik) %>% 
  ungroup() %>% 
  left_join(summaries) %>% 
  filter(!is.na(winner)) %>% 
  select(season, stagecode, tieid, team1, team2, winner, aggscore, loglik)

ll.by.tie

ll.by.tie %>% write_csv('model/post-model-calculations/log-lik-by-tie.csv', na = '')

min.prob.winner = predictions %>%
  left_join(summaries %>% select(season, stagecode, tieid, team1, team2, winner)) %>% 
  group_by(season, stagecode, tieid, team1, team2, winner, t1win) %>% 
  nest() %>% 
  mutate(
    minprobdata = map2(
      data,
      t1win,
      ~.x %>% 
        mutate(
          probwin = case_when(
            .y ~ predictedprobt1,
            TRUE ~ 1 - predictedprobt1
          )
        ) %>% 
        filter(probwin == min(probwin))
    ),
    minprob = map_dbl(minprobdata, ~.x %>% pull(probwin)),
    minprobminute = map_dbl(minprobdata, ~.x %>% pull(minuteclean)),
    minprobscore = map_chr(minprobdata, ~.x %>% mutate(score = glue('{goalst1}-{goalst2}')) %>% pull(score)),
    finalscore = map_chr(data, ~.x %>% filter(minuterown == max(minuterown)) %>% mutate(score = glue('{goalst1}{if_else(goalst1==goalst2 & awaygoalst1>awaygoalst2, "*", "")}-{goalst2}{if_else(goalst1==goalst2 & awaygoalst1<awaygoalst2, "*", "")}')) %>% pull(score))
  ) %>% 
  select(-data, -minprobdata) %>% 
  arrange(minprob) %>% 
  ungroup()
  
min.prob.winner

min.prob.winner %>% write_csv('model/post-model-calculations/min-prob-winner.csv', na = '')

excitement = predictions %>% 
  left_join(summaries %>% select(season, stagecode, tieid, team1, team2, winner)) %>% 
  mutate(chg = abs(chgpredictedprobt1)) %>% 
  group_by(season, stagecode, tieid, team1, team2, winner) %>% 
  summarise(excitement = sum(chg, na.rm = TRUE)) %>% 
  arrange(-excitement)

excitement

excitement %>% write_csv('model/post-model-calculations/excitement.csv', na = '')

tension = predictions %>% 
  left_join(summaries %>% select(season, stagecode, tieid, team1, team2, winner)) %>% 
  filter(!is.na(winner)) %>% 
  mutate(chg = abs(predictedprobt1 - 0.5)) %>% 
  group_by(season, stagecode, tieid, team1, team2, winner) %>% 
  summarise(tension = sum(chg, na.rm = TRUE)) %>% 
  arrange(tension)

tension

tension %>% write_csv('model/post-model-calculations/tension.csv', na = '')