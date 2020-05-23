source('utils.R')

getorretrieve = function(subfolder, url, override = FALSE) {
  fname = url %>% 
    str_split('/') %>% 
    `[[`(1) %>% 
    `[`(length(.)) %>% 
    str_c('.html')
  
  fpath = here('data-get', 'fbref', 'raw', subfolder, fname)
  
  if (!override & file.exists(fpath)) {
    h = read_html(fpath)
  } else {
    h = read_html(url)
    write_html(h, fpath)
  }

  return(h)
}

getorretrieve.seasons = function(url, override = FALSE) {
  return(getorretrieve(subfolder = 'seasons', url = url, override = override))
}

getorretrieve.games = function(url, override = FALSE) {
  return(getorretrieve(subfolder = 'games', url = url, override = override))
}

getorretrieve.teams = function(url, override = FALSE) {
  return(getorretrieve(subfolder = 'teams', url = url, override = override))
}

extractgames = function(h) {
  round = h %>%
    html_nodes('#content > h3') %>% 
    html_text() %>% 
    str_trim()
  
  games = h %>% 
    html_nodes('#content > h3 + div.matchup') %>% 
    map(~html_children(.x))
  
  df = tibble(round, games) %>%
    mutate(
      team1 = map(
        games,
        ~.x %>% 
          html_node('.match-summary .team1') %>% 
          html_text() %>% 
          str_squish()
      ),
      team2 = map(
        games,
        ~.x %>% 
          html_node('.match-summary .team2') %>% 
          html_text() %>% 
          str_squish()
      ),
      teamid1 = map(
        games,
        ~.x %>% 
          html_node('.match-summary .team1 a') %>% 
          html_attr('href') %>%
          str_squish() %>% 
          str_replace('/en/squads/', '') %>% 
          str_sub(end = 8)
      ),
      teamid2 = map(
        games,
        ~.x %>% 
          html_node('.match-summary .team2 a') %>% 
          html_attr('href') %>%
          str_squish() %>% 
          str_replace('/en/squads/', '') %>% 
          str_sub(end = 8)
      ),
      winner = map(
        games,
        ~.x %>% 
          html_node('.match-summary .winner') %>% 
          html_text() %>% 
          str_squish()
      ),
      aggscore = map(
        games,
        ~.x %>% 
          html_node('.match-summary .match-detail') %>% 
          html_text() %>% 
          str_squish()
      ),
      result = map(
        games,
        ~.x %>% 
          html_node('.matchup-note') %>% 
          html_text() %>% 
          str_squish()
      ),
      hometeam1 = map(
        games,
        ~.x %>%
          html_node('.matches > div:nth-child(1)') %>%
          html_node('.matchup-team.team1 small') %>% 
          html_text() %>% 
          str_squish()
      ),
      date1 = map(
        games,
        ~.x %>%
          html_node('.matches > div:nth-child(1)') %>%
          html_node('.match-date small') %>%
          html_text() %>% 
          str_squish()
      ),
      score1 = map(
        games,
        ~.x %>%
          html_node('.matches > div:nth-child(1)') %>%
          html_node('.match-detail .match-score') %>%
          html_text() %>%
          str_squish()
      ),
      url1 = map(
        games,
        ~.x %>%
          html_node('.matches > div:nth-child(1)') %>%
          html_node('.match-detail .match-score > small > a') %>%
          html_attr('href') %>%
          str_squish() %>%
          str_c('https://fbref.com', .)
      ),
      hometeam2 = map(
        games,
        ~.x %>%
          html_node('.matches > div:nth-child(2)') %>%
          html_node('.matchup-team.team1 small') %>% 
          html_text() %>% 
          str_squish()
      ),
      date2 = map(
        games,
        ~.x %>%
          html_node('.matches > div:nth-child(2)') %>%
          html_node('.match-date small') %>%
          html_text() %>% 
          str_squish()
      ),
      score2 = map(
        games,
        ~.x %>%
          html_node('.matches > div:nth-child(2)') %>%
          html_node('.match-detail .match-score') %>%
          html_text() %>%
          str_squish()
      ),
      url2 = map(
        games,
        ~.x %>%
          html_node('.matches > div:nth-child(2)') %>%
          html_node('.match-detail .match-score > small > a') %>%
          html_attr('href') %>%
          str_squish() %>%
          str_c('https://fbref.com', .)
      )
    ) %>% 
    select(-games) %>%
    unnest(
      c(
        team1, team2, teamid1, teamid2,
        winner, aggscore, result,
        hometeam1, date1, score1, url1,
        hometeam2, date2, score2, url2
      ),
      keep_empty = TRUE
    )
  
  return(df)
}

parseevents = function(tm) {
  player = tm %>%
    html_node('a') %>%
    html_text()
  
  playerid = tm %>%
    html_node('a') %>%
    html_attr('href') %>%
    str_replace('/en/players/','') %>%
    str_sub(end = 8)
  
  eventtype = tm %>%
    html_node('div') %>%
    html_attr('class') %>%
    str_replace('event_icon ', '')
  
  minute = tm %>%
    html_text() %>%
    str_trim() %>%
    str_replace('&rsquor;', '') %>%
    str_split(' · ') %>%
    map_chr(`[`, 2)
  
  return(tibble(player, playerid, eventtype, minute))
}

getevents = function(h) {
  aevents = h %>% 
    html_node('div#a.event') %>% 
    html_children() %>% 
    parseevents() %>% 
    mutate(team = 1)
  
  bevents = h %>% 
    html_node('div#b.event') %>% 
    html_children() %>% 
    parseevents() %>% 
    mutate(team = 2)
  
  return(bind_rows(aevents, bevents))
}