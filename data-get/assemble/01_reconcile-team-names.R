library(here)
library(rvest)
library(readxl)
library(tidyverse)


# fbref teams -------------------------------------------------------------

# fbref teams from scrape of CL/EL ties
summaries = read_csv(here('data-get', 'fbref', 'processed', 'two-legged-ties.csv'))

summaries

distinctteams = summaries %>% 
  select(starts_with('team')) %>% 
  pivot_longer(starts_with('team')) %>% 
  mutate(name = str_sub(name, end = -2)) %>% 
  pivot_wider(names_from = name, values_from = value) %>%
  unnest(c(team, teamid)) %>% 
  distinct() %>%
  select(club = team, clubid = teamid) %>% 
  group_by(clubid) %>% 
  nest() %>% 
  mutate(clubshortnames = map_chr(data, ~str_c(.x$club, collapse = '|'))) %>% 
  select(-data)

distinctteams

# fbref teams from country index pages
fbrefteams = read_csv(here('data-get', 'fbref', 'processed', 'fbref-all-teams.csv'))
fbrefteams

# join for master fbref list
europeteamsfbref = fbrefteams %>% 
  select(clubid, club = Squad, country, countrycode = countrycode3, governingbody) %>% 
  # manually add this missing team
  bind_rows(
    tibble(
      club = 'Juventus',
      clubid = 'e0652b02',
      country = 'Italy',
      countrycode = 'ITA',
      governingbody = 'UEFA'
    )
  ) %>% 
  right_join(distinctteams, by = 'clubid') %>% 
  arrange(club)

# this is a list of ALL clubids that were picked up by the scrape
# cross-referenced to their full names from the country indices
europeteamsfbref

europeteamsfbref %>% write_csv(here('data-get', 'assemble', 'europe-teams-fbref.csv'), na = '')


# oddsportal teams --------------------------------------------------------

# get oddsportal teams
odds = read_csv(here('data-get', 'oddsportal', 'processed', 'odds.csv'), na = '-')

odds

europeteamsodds = odds %>% 
  filter(season >= 2015) %>%
  filter(round != 'Group Stage') %>%
  select(teamh, teama) %>% 
  pivot_longer(starts_with('team')) %>% 
  mutate(name = str_sub(name, end = -2)) %>% 
  pivot_wider(names_from = name, values_from = value) %>% 
  unnest(team) %>% 
  distinct() %>% 
  arrange(team)

europeteamsodds

europeteamsodds %>% write_csv(here('data-get', 'assemble', 'europe-teams-odds.csv'), na = '')

# bring in manually joined list
joined = read_csv(here('data-get', 'assemble', 'name join - joining-work.csv'))

joined %>% mutate(nc = nchar(fbrefid)) %>% count(nc)

joined = joined %>% 
  # manual fix
  mutate(
    fbrefid = str_pad(fbrefid, width = 8, side = 'left', pad = '0')
  )

joined

joined %>% mutate(nc = nchar(fbrefid)) %>% count(nc)
joined %>% filter(str_detect(fbrefid, '3022')) # why above fix was necessary

# fbref teams in joined CL/El-index list that did not get attached in manual join
# this is usually because of misfires on my part
didntmatch = europeteamsfbref %>% anti_join(joined %>% select(clubid = fbrefid))

didntmatch

# take list of oddsportal teams names and link it to previously completed joining
# columns: 1) oddsportal team name 2) fbrefid 3) fbref team name 4) fbref country
joiningprogress = europeteamsodds %>% left_join(joined)

joiningprogress

# go back and fill these in
needsmatch = joiningprogress %>% filter(is.na(fbrefid))

needsmatch

# fully joined list
# paste first two columns into google sheet
joiningprogress %>% write_csv(here('data-get', 'assemble', 'joining-progress.csv'), na = '')
