library(here)
library(tidyverse)

raw.odds = read_csv(here('data-get', 'oddsportal', 'processed', 'odds.csv'), na = '-')

raw.odds 

namesjoined = read_csv(here('data-get', 'assemble', 'teams', 'names-joined.csv'))

namesjoined

summaries = read_csv(here('data-get', 'fbref', 'processed', 'two-legged-ties.csv'))

summaries

oddsjoined = raw.odds %>% 
  filter(season >= 2015) %>% # odds filter, update when adding new data
  filter(round != 'Group Stage') %>%
  # custom filters since 2021 had fewer two-legged ties
  filter(
    !(season == 2021 &
        comp == 'europa-league' & 
        round != 'Play Offs')
  ) %>% 
  filter(
    !(season == 2021 &
        comp == 'champions-league' &
        round != 'Play Offs' &
        !(date >= '2020-09-22' & date <= '2020-09-30'))
  ) %>% 
  left_join(namesjoined %>% select(teamh = team, teamidh = fbrefid)) %>% 
  left_join(namesjoined %>% select(teama = team, teamida = fbrefid)) %>% 
  mutate(tieid = map2_chr(teamidh, teamida, ~str_c(sort(c(.x, .y)), collapse = '|'))) %>% 
# 
# oddsjoined
# 
# oddsjoined = oddsjoined %>%
#   anti_join(
#     oddsjoined %>%
#       count(season, tieid) %>%
#       filter(n != 2)
#   ) %>%
  # view()
  group_by(season, tieid) %>% 
  mutate(tieorder = rank(date)) %>% 
  ungroup() %>% 
  select(comp, season, tieid, round, tieorder, date, everything()) %>% 
  select(-page)

oddsjoined

reformat = function(df, tienumber) {
  df %>% 
    filter(tieorder == tienumber) %>% 
    select(
      comp:tieid, tieorder,
      probh:proba
    ) %>% 
    rename_at(vars(starts_with('prob')), list(~str_c(., tienumber))) %>% 
    select(-tieorder)
}

oddsbytie = full_join(
  reformat(oddsjoined, tienumber = 1),
  reformat(oddsjoined, tienumber = 2)
)

oddsbytie

# final table
odds = summaries %>%
  mutate(season = as.numeric(str_sub(szn, end = 4)) + 1) %>% 
  select(season, stagecode, tieid) %>% 
  left_join(oddsbytie %>% select(-comp))

odds

# summaries %>%
#   mutate(season = as.numeric(str_sub(szn, start = -4))) %>%
#   right_join(
#     odds %>% filter(is.na(probh1+probd1+proba1))
#   ) %>%
#   view()

# save final table
odds %>% write_csv(here('data-get', 'assemble', 'odds', 'odds.csv'), na = '')
odds %>% write_rds(here('data', 'odds.rds'))
