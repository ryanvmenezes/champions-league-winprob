library(here)
library(tidyverse)

ties = read_csv(here('data-get', 'fbref', 'processed', 'two-legged-ties.csv'))

ties

results = ties %>% 
  mutate(szn = as.numeric(str_sub(szn, end = 4)) + 1) %>% 
  rename(season = szn) %>% 
  separate(aggscore, into = c('aggscore1','aggscore2'), remove = FALSE) %>% 
  mutate(
    t1win = (winner == team1),
    agr = str_detect(str_to_lower(result), 'away goals'),
    aet = str_detect(str_to_lower(result), 'extra time'),
    pk = str_detect(str_to_lower(result), 'penalty')
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

# events ------------------------------------------------------------------

events = read_csv(here('data-get', 'fbref', 'processed', 'match-events.csv'))

events

events %>% count(eventtype)

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
  ) %>% 
  left_join(
    results %>%
      select(season, stagecode, tieid, t1win, agr, aet, pk),
    by = c("season", "stagecode", "tieid")
  ) %>% 
  group_by(season, stagecode, tieid, t1win, agr, aet, pk) %>% 
  nest()

eventscleaned

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

eventscleaned = eventscleaned %>% 
  mutate(minutematrix = map2(data, aet, expandminutes))

eventscleaned
 
# eventscleaned %>% filter(aet) %>% head(1) %>% pull(minutematrix) %>% `[[`(1) %>% tail()

# eventscleaned %>%
#   filter(season == 2018) %>%
#   filter(tieid == '53a2f082|e0652b02') %>%
#   pull(minutematrix) %>% 
#   `[[`(1) %>%
#   tail()

# 
# eventscleaned[764,]
# eventscleaned$data[[764]] %>% arrange(minuteclean)
# eventscleaned$data[[764]] %>% expandminutes() %>% tail()
# eventscleaned$data[[764]] %>% expandminutes() %>% filter(minuteclean > 90) 

eventsmatrix = eventscleaned %>% 
  select(-data) %>% 
  unnest(minutematrix) %>% 
  ungroup()

eventsmatrix

eventsmatrix %>% write_csv('data-get/assemble/events-by-minute.csv', na = '')


# odds --------------------------------------------------------------------

odds = read_csv(here('data-get', 'assemble', 'odds-joined.csv'))

odds

reformat = function(df, tienumber) {
  df %>% 
    filter(tieorder == tienumber) %>% 
    select(
      comp:tieid, tieorder,
      # scoreh:scorea,
      # teamh:teama,
      probh:proba
    ) %>% 
    # rename_at(vars(starts_with('score')), list(~str_c(., tienumber))) %>% 
    # rename_at(vars(starts_with('team')), list(~str_c(., tienumber))) %>%
    rename_at(vars(starts_with('prob')), list(~str_c(., tienumber))) %>% 
    select(-tieorder)
}

oddsbytie = full_join(
  reformat(odds, tienumber = 1),
  reformat(odds, tienumber = 2)
)

oddsbytie

# oddsbytie %>% summarise(sum(teamh2 != teama1))
# oddsbytie %>% summarise(sum(teamh1 != teama2))

oddsbytie %>%
  write_csv(here('data-get', 'assemble', 'all-tie-odds.csv'), na = '')


# join --------------------------------------------------------------------

eventsmatrix

oddsbytie

minutematrix = eventsmatrix %>%
  left_join(oddsbytie %>% select(-comp)) %>% 
  arrange(season, stagecode, tieid, minuteclean, minute)

minutematrix

minutematrix %>%
  write_rds(here('data-get', 'assemble', 'minute-matrix.rds'), compress = 'gz')


minutematrix %>%
  write_csv(here('data-get', 'assemble', 'minute-matrix.csv'), na = '')


multipleminutes = minutematrix %>% 
  group_by(season, stagecode, tieid, minuteclean) %>% 
  count() %>% 
  filter(n != 1) %>% 
  left_join(minutematrix) 

multipleminutes %>% 
  write_csv('data-get/assemble/multiple-minutes.csv', na = '')

# create summaries --------------------------------------------------------

# bring in the missing data entries
missing = read_csv(here('data-get', 'assemble', 'missing-ties.csv'))

missing

assemblingsummary = results %>% 
  bind_rows(
    missing %>%
      mutate(has_events = FALSE)
  ) %>%
  left_join(
    # mark ties that have no odds
    oddsbytie %>% 
      distinct(season, tieid) %>% 
      mutate(has_odds = TRUE)
  ) %>% 
  mutate(
    has_events = replace_na(has_events, TRUE),
    has_odds = replace_na(has_odds, FALSE)
  ) %>% 
  arrange(season, stagecode, tieid)

assemblingsummary

assemblingsummary %>% write_csv(here('data-get', 'assemble', 'matrix-leg-summary.csv'), na = '')

# assemblingsummary %>% filter(!has_events)
# 
# assemblingsummary %>% count(has_events, has_odds)
# 
# assemblingsummary %>% filter(!has_odds)
