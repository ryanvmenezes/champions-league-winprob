library(purrr)
library(jsonlite)
library(tidyverse)

json = fromJSON('data/footballdata/raw/2017.json')

names(json)

str(json, max.level = 1)
str(json$matches, max.level = 1)

matches = json$matches %>% flatten()
str(matches, max.level = 1)

matchinfo = matches %>%
  select(id, date = utcDate, stage,
         teamH = homeTeam.name, idH = homeTeam.id,
         teamA = awayTeam.name, idA = awayTeam.id,
         duration = score.duration,
         scoreH = score.fullTime.homeTeam, scoreA = score.fullTime.awayTeam,
         scoreHet = score.extraTime.homeTeam, scoreAet = score.extraTime.awayTeam,
         scoreHpens = score.penalties.homeTeam, scoreApens = score.penalties.awayTeam) %>%
  mutate(scoreHet = replace_na(scoreHet, 0),
         scoreAet = replace_na(scoreAet, 0),
         scoreHpens = replace_na(scoreHpens, 0),
         scoreApens = replace_na(scoreApens, 0),
         scoreH90 = (scoreH - scoreHet),
         scoreA90 = (scoreA - scoreAet)) %>% 
  as_tibble() %>% 
  select(id:scoreA, scoreH90, scoreA90, everything()) %>% 
  mutate(tieid = map2_chr(idH, idA, ~str_c(sort(c(.x, .y)), collapse = '|')))

matchinfo
