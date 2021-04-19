library(here)
library(tidyverse)

summaries = read_rds(here('data', 'summary.rds'))
odds = read_rds(here('data', 'odds.rds'))
events = read_rds(here('data', 'events.rds'))

minute.data = summaries %>% 
  filter(has_events) %>% 
  filter(!has_invalid_match) %>% 
  left_join(events, by = c("season", "stagecode", "tieid", "aet", "has_events", "in_progress")) %>% 
  left_join(odds, by = c("season", "stagecode", "tieid")) %>% 
  transmute(
    season, stagecode, tieid,
    t1win,
    prob.h.g1 = probh1,
    prob.d.g1 = probd1,
    prob.a.g1 = proba1,
    minuteclean, minuterown,
    goals.t1 = goalst1,
    goals.t2 = goalst2,
    away.goals.t1 = awaygoalst1,
    away.goals.t2 = awaygoalst2,
    players.t1 = 11 - redcardst1,
    players.t2 = 11 - redcardst2,
    player, playerid, eventtype
  ) %>% 
  mutate(
    prob.h.g1 = replace_na(prob.h.g1, 0.33),
    prob.d.g1 = replace_na(prob.d.g1, 0.33),
    prob.a.g1 = replace_na(prob.a.g1, 0.33)
  ) %>% 
  # add logical flag to indicate goal/away goal (for plotting)
  group_by(season, stagecode, tieid, t1win) %>% 
  mutate(
    is.goal = goals.t1 != lag(goals.t1) | goals.t2 != lag(goals.t2),
    is.goal = replace_na(is.goal, FALSE),
    is.away.goal = away.goals.t1 != lag(away.goals.t1) | away.goals.t2 != lag(away.goals.t2),
    is.away.goal = replace_na(is.away.goal, FALSE),
    is.red.card = players.t1 != lag(players.t1) | players.t2 != lag(players.t2),
    is.red.card = replace_na(is.red.card, FALSE)
  ) %>% 
  ungroup()

minute.data

minute.data %>% write_rds('model/v3/predictors/minutes.rds', compress = 'gz')

# calculate final scores of each leg

total.goals.by.game = minute.data %>% 
  filter(minuteclean <= 90) %>% 
  group_by(season, stagecode, tieid) %>% 
  filter(minuterown == max(minuterown)) %>% 
  ungroup() %>% 
  select(
    season, stagecode, tieid,
    goals.t1.g1.final = goals.t1,
    goals.t2.g1.final = goals.t2
  ) %>% 
  left_join(
    summaries %>%
      transmute(
        season, stagecode, tieid,
        goals.t1.agg = as.numeric(aggscore1),
        goals.t2.agg = as.numeric(aggscore2),
      )
  ) %>% 
  mutate(
    goals.t1.g2.final = goals.t1.agg - goals.t1.g1.final,
    goals.t2.g2.final = goals.t2.agg - goals.t2.g1.final,
  ) %>% 
  select(
    season, stagecode, tieid,
    ends_with('final'),
    ends_with('agg')
  )

total.goals.by.game

# leg 1 predictors --------------------------------------------------------

leg1.prep.data = minute.data %>% 
  left_join(total.goals.by.game) %>% 
  mutate(
    goals.t1 = case_when(minuteclean <= 90 ~ goals.t1),
    goals.t2 = case_when(minuteclean <= 90 ~ goals.t2),
    away.goals.t1 = case_when(minuteclean <= 90 ~ away.goals.t1),
    away.goals.t2 = case_when(minuteclean <= 90 ~ away.goals.t2),
    players.t1 = case_when(minuteclean <= 90 ~ players.t1),
    players.t2 = case_when(minuteclean <= 90 ~ players.t2),
  ) %>% 
  fill(
    goals.t1, goals.t2,
    away.goals.t1, away.goals.t2,
    players.t1, players.t2,
    .direction = 'down'
  )

leg1.team1.data = leg1.prep.data %>% 
  transmute(
    season, stagecode, tieid,
    minuteclean, minuterown,
    goals = goals.t1,
    goals.left = goals.t1.g1.final - goals.t1,
    prob.diff = prob.h.g1 - prob.a.g1,
    goals.edge = goals.t1 - goals.t2,
    away.goals.edge = away.goals.t1 - away.goals.t2,
    players.edge = players.t1 - players.t2,
    home = 1
  )

leg1.team2.data = leg1.prep.data %>% 
  transmute(
    season, stagecode, tieid,
    minuteclean, minuterown,
    goals = goals.t2,
    goals.left = goals.t2.g1.final - goals.t2,
    prob.diff = prob.a.g1 - prob.h.g1,
    goals.edge = goals.t2 - goals.t1,
    away.goals.edge = away.goals.t2 - away.goals.t1,
    players.edge = players.t2 - players.t1,
    home = 0
  )

leg1.data = bind_rows(leg1.team1.data, leg1.team2.data)

leg1.data

# leg 2 predictors --------------------------------------------------------

leg2.prep.data = minute.data %>% 
  left_join(total.goals.by.game) %>% 
  mutate(
    goals.t1.g2 = case_when(minuteclean > 90 ~ goals.t1 - goals.t1.g1.final, TRUE ~ 0),
    goals.t2.g2 = case_when(minuteclean > 90 ~ goals.t2 - goals.t2.g1.final, TRUE ~ 0),
    players.t1.g2 = case_when(minuteclean > 90 ~ players.t1, TRUE ~ 11),
    players.t2.g2 = case_when(minuteclean > 90 ~ players.t2, TRUE ~ 11),
  )

leg2.team1.data = leg2.prep.data %>% 
  transmute(
    season, stagecode, tieid,
    minuteclean, minuterown,
    goals = goals.t1.g2,
    goals.left = goals.t1.g2.final - goals.t1.g2,
    prob.diff = prob.h.g1 - prob.a.g1,
    goals.edge = goals.t1 - goals.t2,
    away.goals.edge = away.goals.t1 - away.goals.t2,
    players.edge = players.t1.g2 - players.t2.g2,
    home = 0
  )

leg2.team2.data = leg2.prep.data %>% 
  transmute(
    season, stagecode, tieid,
    minuteclean, minuterown,
    goals = goals.t2.g2,
    goals.left = goals.t2.g2.final - goals.t2.g2,
    prob.diff = prob.a.g1 - prob.h.g1,
    goals.edge = goals.t2 - goals.t1,
    away.goals.edge = away.goals.t2 - away.goals.t1,
    players.edge = players.t2.g2 - players.t1.g2,
    home = 1
  )

leg2.data = bind_rows(leg2.team1.data, leg2.team2.data)

leg2.data

tie.data = bind_rows(
  leg1.data %>% mutate(leg = 1),
  leg2.data %>% mutate(leg = 2)
)

train = tie.data %>% filter(season %in% c(2015, 2016, 2017, 2018))

tie.data %>% write_rds('model/v3/predictors/all.rds', compress = 'gz')
train %>% write_rds('model/v3/predictors/train.rds', compress = 'gz')
