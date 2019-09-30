library(here)
library(jsonlite)
library(tidyverse)

readmatches = function(s, c) {
  fname = str_c(c, '-matches-', s, '.json')
  fpath = here('data-get', 'footballdata', 'raw', fname)
  json = fromJSON(fpath)
  json$matches %>% 
    jsonlite::flatten() %>%
    as_tibble()
}

parsematches = function(jsonobj) {
  jsonobj %>%
    select(
      matchid = id, date = utcDate,
      stage,teamH = homeTeam.name, idH = homeTeam.id,
      teamA = awayTeam.name, idA = awayTeam.id,
      duration = score.duration,
      scoreH = score.fullTime.homeTeam, scoreA = score.fullTime.awayTeam,
      scoreHet = score.extraTime.homeTeam, scoreAet = score.extraTime.awayTeam,
      scoreHpens = score.penalties.homeTeam, scoreApens = score.penalties.awayTeam
    ) %>%
    mutate(
      scoreHet = replace_na(scoreHet, 0),
      scoreAet = replace_na(scoreAet, 0),
      scoreHpens = replace_na(scoreHpens, 0),
      scoreApens = replace_na(scoreApens, 0),
      scoreH90 = (scoreH - scoreHet),
      scoreA90 = (scoreA - scoreAet)
    ) %>%
    select(
      matchid:scoreA, scoreH90, scoreA90, everything()
    ) %>%
    mutate(
      # tie id is the sorted combo of the two team ids
      tieid = map2_chr(idH, idA, ~str_c(sort(c(.x, .y)), collapse = '|'))
    ) %>%
    arrange(date) %>%
    group_by(stage, tieid) %>%
    mutate(tieno = rank(date)) %>% 
    ungroup()
}

parsetwolegties = function(matches) {
  twolegmatches = matches %>% 
    filter(
      stage %in% c(
        "1ST_QUALIFYING_ROUND","2ND_QUALIFYING_ROUND","3RD_QUALIFYING_ROUND",
        "PLAY_OFF_ROUND","ROUND_OF_16","QUARTER_FINALS","SEMI_FINALS"
      )
    )
  
  full_join(
    twolegmatches %>% filter(tieno == 1) %>% select(-tieno),
    twolegmatches %>% filter(tieno == 2) %>% select(-tieno),
    by = c('stage','tieid'),
    suffix = c('.g1','.g2')
  ) %>%
    mutate(
      goals1 = scoreH.g1 + scoreA.g2,
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
      pens2 = scoreHpens.g2
    ) %>% 
    select(
      stage, tieid,
      team1id = idH.g1, team2id = idA.g1,
      team1 = teamH.g1, team2 = teamA.g1, 
      matchid.g1, matchid.g2,
      goals1:pens2
    ) %>% 
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
}

parsegoals = function(jsonobj) {
  map2_df(
    jsonobj$id,
    jsonobj$goals,
    ~.y %>%
      jsonlite::flatten() %>%
      mutate(matchid = .x) %>%
      as_tibble()
    ) %>%
    select(
      matchid,
      minute, extraTime,
      goaltype = type,
      team.id:assist.name
      )
}

parsebookings = function(jsonobj) {
  map2_df(
    jsonobj$id,
    jsonobj$bookings,
    ~.y %>%
      jsonlite::flatten() %>%
      mutate(matchid = .x) %>%
      as_tibble()
    ) %>% 
    select(
      matchid, minute, card,
      team.id, team.name,
      player.id, player.name
      )
}

parsesubs = function(jsonobj) {
  map2_df(
    jsonobj$id,
    jsonobj$substitutions,
    ~.y %>%
      jsonlite::flatten() %>%
      mutate(matchid = .x) %>%
      as_tibble()
    ) %>% 
    select(
      matchid, minute, team.id, team.name,
      playerOut.id, playerOut.name,
      playerIn.id, playerIn.name
      )
}

# seasons = tibble(season = 2017:2019)
seasons = expand.grid(
  comp = c('CL'), # 'el'
  season = 2017:2019
) %>% 
  as_tibble()

data = seasons %>% 
  mutate(json = map2(season, comp, readmatches))

data

summaries = data %>% 
  mutate(
    matches = map(json, parsematches),
    twolegties = map(matches, parsetwolegties),
    goals = map(json, parsegoals),
    bookings = map(json, parsebookings),
    subs = map(json, parsesubs)
    )

summaries

tblnames = summaries %>% 
  select(matches:subs) %>% 
  names() 

tables = tblnames %>% 
  map(~summaries %>% select(comp, season, .x) %>% unnest())
names(tables) = tblnames
str(tables, max.level = 1)

walk(
  tblnames,
  ~write_csv(tables[[.x]], here('data-get','footballdata','processed', str_c(.x, '.csv')), na = '')
  )


# check that goal totals are same
# summaries$matches[3][[1]] %>% transmute(scoreH + scoreA) %>% sum(na.rm = TRUE)
