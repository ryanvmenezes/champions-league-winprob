library(here)
library(rvest)
library(readxl)
library(tidyverse)
library(googlesheets4)

# fbref teams -------------------------------------------------------------

# fbref teams from scrape of CL/EL ties
summaries = read_csv(here('data-get', 'fbref', 'processed', 'two-legged-ties.csv'))

summaries

distinctteams = summaries %>% 
  select(starts_with('team')) %>% 
  pivot_longer(starts_with('team')) %>% 
  mutate(name = str_sub(name, end = -2)) %>% 
  pivot_wider(names_from = name, values_from = value, values_fn = list(value = list)) %>%
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
  right_join(distinctteams, by = 'clubid') %>%
  arrange(club)

# this is a list of ALL clubids that were picked up by the scrape
# cross-referenced to their full names from the country indices
europeteamsfbref

europeteamsfbref %>% write_csv(here('data-get', 'assemble', 'teams', 'europe-teams-fbref.csv'), na = '')

# oddsportal teams --------------------------------------------------------

# get oddsportal teams
odds = read_csv(here('data-get', 'oddsportal', 'processed', 'odds.csv'), na = '-')

odds

odds %>% tail(20)

europeteamsodds = odds %>% 
  filter(season >= 2015) %>%
  filter(round != 'Group Stage') %>%
  select(teamh, teama) %>% 
  pivot_longer(starts_with('team')) %>% 
  mutate(name = str_sub(name, end = -2)) %>% 
  pivot_wider(names_from = name, values_from = value, values_fn = list(value = list)) %>% 
  unnest(team) %>% 
  distinct() %>% 
  arrange(team)

europeteamsodds

europeteamsodds %>% write_csv(here('data-get', 'assemble', 'teams', 'europe-teams-odds.csv'), na = '')

# bring in manually joined list
sheeturl = 'https://docs.google.com/spreadsheets/d/19yv-uBPRs5JqXiWuLwhsbMQNMtiW5UHOnLpoX-DWjBM/edit#gid=0'
sheetname = 'joining-work'
gs4_auth(email = 'ryanvmenezes@gmail.com')

joined = read_sheet(sheeturl, sheetname)

joined

joined = joined %>% 
  # manual fix for entirely numeric string that has leading 0
  mutate(
    fbrefid = map_chr(fbrefid, as.character),
    fbrefid = str_pad(fbrefid, width = 8, side = 'left', pad = '0')
  )

joined

# fbref teams in joined CL/El-index list that did not get attached in manual join
# this is usually because of misfires on my part, or a new team to the data
didntmatch = europeteamsfbref %>% anti_join(joined %>% select(clubid = fbrefid))

didntmatch

# take list of oddsportal teams names and link it to previously completed joining
# columns: 1) oddsportal team name 2) fbrefid 3) fbref team name 4) fbref country
joiningprogress = europeteamsodds %>% left_join(joined)

joiningprogress

# go back and fill these in
needsmatch = joiningprogress %>% filter(is.na(fbrefid))

needsmatch

# fully joined list - write it back to google sheet
joiningprogress %>% write_sheet(ss = sheeturl, sheet = sheetname)
joiningprogress %>% write_csv(here('data-get', 'assemble', 'teams', 'names-joined.csv'))

# create final teams table

teams = joined %>%
  drop_na(matchclub) %>% 
  group_by(teamname = matchclub, fbrefid, teamcountry = matchcountry) %>% 
  summarise(oddsnames = str_c(team, collapse = '||')) %>% 
  ungroup()

teams

# final table
teams %>% write_csv(here('data-get', 'assemble', 'teams', 'teams.csv'))
teams %>% write_rds(here('data', 'teams.rds'))

