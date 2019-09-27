library(purrr)
library(jsonlite)
library(tidyverse)

json = fromJSON('data/footballdata/raw/CL-2018.json')

names(json)

str(json, max.level = 1)
str(json$matches, max.level = 1)

matches = json$matches %>% 
  flatten() %>% 
  as_tibble()

matches %>% head()

matchinfo = matches %>%
  select(gameid = id, date = utcDate, stage,
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
  select(gameid:scoreA, scoreH90, scoreA90, everything()) %>% 
  mutate(tieid = map2_chr(idH, idA, ~str_c(sort(c(.x, .y)), collapse = '|'))) %>% 
  arrange(date) %>% 
  group_by(stage, tieid) %>% 
  mutate(tieno = rank(date))

View(matchinfo)

# lfc games
matchinfo %>% filter(str_detect(tieid, '^64\\||\\|64$')) %>% View()

matches %>% count(stage)

twolegmatches = matchinfo %>% 
  filter(stage %in% c("1ST_QUALIFYING_ROUND","2ND_QUALIFYING_ROUND","3RD_QUALIFYING_ROUND",
                      "PLAY_OFF_ROUND","ROUND_OF_16","QUARTER_FINALS","SEMI_FINALS"))

twolegsinfo = full_join(twolegmatches %>% filter(tieno == 1) %>% select(-tieno),
                        twolegmatches %>% filter(tieno == 2) %>% select(-tieno),
                        by = c('stage','tieid'),
                        suffix = c('.g1','.g2')) %>%
  mutate(goals1 = scoreH.g1 + scoreA.g2,
         goals2 = scoreA.g1 + scoreH.g2,
         awaygoals1 = scoreA.g2,
         awaygoals2 = scoreA.g1,
         goals1ft = scoreH.g1 + scoreA90.g2,
         goals2ft = scoreA.g1 + scoreH90.g2,
         awaygoals1ft = scoreA90.g2,
         awaygoals2ft = scoreA.g1,
         goals1et = scoreAet.g2,
         goals2et = scoreHet.g2,
         pens1 = scoreApens.g2,
         pens2 = scoreHpens.g2) %>% 
  select(stage, tieid,
         team1id = idH.g1, team2id = idA.g1,
         team1 = teamH.g1, team2 = teamA.g1, 
         gameid.g1, gameid.g2,
         goals1:pens2) %>% 
  mutate(
    winner = case_when(
      goals1 > goals2 ~ team1,
      goals2 > goals1 ~ team2,
      goals1 == goals2 ~ case_when(
        awaygoals1 > awaygoals2 ~ team1,
        awaygoals2 > awaygoals1 ~ team2,
        awaygoals1 == awaygoals2 ~ case_when(
          pens1 > pens2 ~ team1,
          pens2 > pens1 ~ team2,
        )
      )
    ),
    aet = (goals1ft == goals2ft) & (awaygoals1ft == awaygoals2ft),
    agr = (goals1 == goals2) & (awaygoals1 != awaygoals2),
    pk = (goals1 == goals2) & (awaygoals1 == awaygoals2),
    result = str_c(
      team1,' (', goals1, '-', goals2,
      case_when(aet ~ ' aet) ', TRUE ~ ') '),
      team2,
      case_when(
        pk ~ str_c(', ', winner, ' won on penalties'),
        agr ~ str_c(', ', winner, ' won on away goals'),
        TRUE ~ ''
      )
    )
  )

matches$goals[1][[1]] %>% flatten()
matches$bookings[1][[1]] %>% flatten()
matches$substitutions[1][[1]] %>% flatten()

goals = map2_df(matches$id,
                matches$goals,
                ~.y %>% 
                  flatten() %>%
                  mutate(gameid = .x) %>%
                  as_tibble()) %>% 
  select(gameid, minute, extraTime, type, team.id:assist.name)

subs = map2_df(matches$id,
                matches$substitutions,
                ~.y %>% 
                  flatten() %>%
                  mutate(gameid = .x) %>%
                  as_tibble()) %>% 
  select(gameid, minute, team.id, team.name, playerOut.id, playerOut.name, playerIn.id, playerIn.name)

bookings = map2_df(matches$id,
                   matches$bookings,
                   ~.y %>%
                     flatten() %>%
                     mutate(gameid = .x) %>%
                     as_tibble()) %>% 
  select(gameid, minute, card, team.id, team.name, player.id, player.name)
