library(here)
library(tidyverse)

this.version = 'v3'

source(here('model', 'utils.R'))

all.data

summaries

goals.by.game = all.data %>% 
  filter(season < test.season.cutoff) %>% 
  filter(minuteclean <= 90) %>% 
  group_by(season, stagecode, tieid) %>% 
  filter(minuterown == max(minuterown)) %>% 
  ungroup() %>% 
  select(
    season, stagecode, tieid,
    g1t1goals = goalst1,
    g1t2goals = goalst2
  ) %>% 
  left_join(summaries %>% select(season, stagecode, tieid, aggscore1, aggscore2)) %>% 
  mutate(
    aggscore1 = as.numeric(aggscore1),
    aggscore2 = as.numeric(aggscore2),
    g2t1goals = aggscore1 - g1t1goals,
    g2t2goals = aggscore2 - g1t2goals,
  )

goals.by.game

leg1prep = all.data %>% 
  left_join(goals.by.game) %>% 
  mutate(
    goalst1 = case_when(minuteclean <= 90 ~ goalst1),
    goalst2 = case_when(minuteclean <= 90 ~ goalst2),
  ) %>% 
  fill(goalst1, goalst2, .direction = 'down')

leg1t1 = leg1prep %>% 
  transmute(
    season, stagecode, tieid,
    minuteclean, minuterown,
    goals.left = g1t1goals - goalst1,
    prob.diff = probh1 - proba1,
    goals.edge = goalst1 - goalst2,
    away.goals.edge = case_when(minuteclean <= 90 ~ awaygoalst1 - awaygoalst2),
    men.edge = case_when(minuteclean <= 90 ~ redcardst1diff * -1),
    home = 1
  ) %>% 
  fill(men.edge, away.goals.edge, .direction = 'down')

leg1t2 = leg1prep %>% 
  transmute(
    season, stagecode, tieid,
    minuteclean, minuterown,
    goals.left = g1t2goals - goalst2,
    prob.diff = proba1 - probh1,
    goals.edge = goalst2 - goalst1,
    away.goals.edge = case_when(minuteclean <= 90 ~ awaygoalst2 - awaygoalst1),
    men.edge = case_when(minuteclean <= 90 ~ redcardst1diff * 1),
    home = 0
  ) %>% 
  fill(away.goals.edge, men.edge, .direction = 'down')

leg1 = bind_rows(leg1t1, leg1t2)

leg1

leg2prep = all.data %>% 
  left_join(goals.by.game) %>% 
  mutate(
    goalst1g2 = case_when(minuteclean > 90 ~ goalst1 - g1t1goals),
    goalst2g2 = case_when(minuteclean > 90 ~ goalst2 - g1t2goals),
  ) %>% 
  fill(goalst1g2, goalst2g2, .direction = 'up')

leg2t1 = leg2prep %>% 
  transmute(
    season, stagecode, tieid,
    minuteclean, minuterown,
    goals.left = g2t1goals - goalst1g2,
    prob.diff = probh1 - proba1,
    goals.edge = goalst1 - goalst2,
    away.goals.edge = awaygoalst1 - awaygoalst2,
    men.edge = case_when(minuteclean > 90 ~ redcardst1diff * 1, TRUE ~ 0),
    home = 0
  )
  
leg2t2 = leg2prep %>% 
  transmute(
    season, stagecode, tieid,
    minuteclean, minuterown,
    goals.left = g2t2goals - goalst2g2,
    prob.diff = proba1 - probh1,
    goals.edge = goalst2 - goalst1,
    away.goals.edge = awaygoalst2 - awaygoalst1,
    men.edge = case_when(minuteclean > 90 ~ redcardst1diff * -1, TRUE ~ 0),
    home = 1
  )

leg2 = bind_rows(leg2t1, leg2t2)

# leg2 %>% 
#   filter(tieid == '44b65410|50f2a074') %>%
#   view()

leg1 %>% write_rds(here('model', this.version, 'files', 'leg1.rds'), compress = 'gz')
leg2 %>% write_rds(here('model', this.version, 'files', 'leg2.rds'), compress = 'gz')
