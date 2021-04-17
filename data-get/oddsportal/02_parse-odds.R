library(tidyverse)
library(lubridate)
library(here)
library(rvest)

rawfiles = tibble(
  f = dir(here('data-get','oddsportal','raw')),
  p = here('data-get','oddsportal','raw', f)
) %>% 
  mutate(h = map(p, read_html))

parsedtbls = rawfiles %>% 
  mutate(
    t = map(
      h,
      ~.x %>%
        html_node('table#tournamentTable') %>%
        html_table() %>% 
        as_tibble(.name_repair = ~str_c('c', 1:length(.))) %>%
        filter(c1 != '') %>%
        mutate(
          c8 = case_when(
            c5 == 'X' ~ c1,
            TRUE ~ NA_character_
            )
        ) %>%
        fill(c8, .direction = 'down') %>%
        filter(c5 != 'X') %>%
        separate(c8, into = c('date', 'round'), sep = ' - ') %>%
        separate(c2, into = c('teamh', 'teama'), sep = ' - ') %>%
        select(round, date, teamh, teama, finalscore = c3, oddsh = c4, oddsd = c5, oddsa = c6) %>%
        mutate(
          oddsh = as.character(oddsh),
          oddsd = as.character(oddsd),
          oddsa = as.character(oddsa)
        )
    )
  )

allodds = parsedtbls %>% 
  mutate(f = str_replace(f, '.html','')) %>% 
  separate(f, into = c('l1','l2','y1','y2','page','p')) %>% 
  unite('lg', l1:l2, sep = '-') %>% 
  select(comp = lg, season = y2, page = p, table = t) %>% 
  unnest(cols = c(table)) %>% 
  mutate(
    pens = str_detect(finalscore, 'pen.'),
    awarded = str_detect(finalscore, 'award.'),
    extratime = str_detect(finalscore, 'ET'),
    cancelled = str_detect(finalscore, 'canc.'),
    finalscore = case_when(
      awarded ~ NA_character_,
      cancelled ~ NA_character_,
      TRUE ~ finalscore
      ),
    finalscore = str_replace(finalscore, '\\spen.|\\sET', ''),
    date = case_when(
      str_detect(date, 'Yesterday') ~ str_c(date, year(today())),
      str_detect(date, 'Today') ~ str_c(date, year(today())),
      TRUE ~ date
    ),
    date = str_remove(date, 'Yesterday, '),
    date = str_remove(date, 'Today, '),
    date = dmy(date)
  ) %>% 
  separate(finalscore, into = c('scoreh','scorea'), sep = ':')

convertodds = function(o) {
  n = as.numeric(o)
  p = NA_real_
  if (is.na(n)) { return(p) }
  if (n < 0) { p = -n / (-n + 100) }
  if (n > 0) { p = 100 / (n + 100) }
  p
}

allodds = allodds %>% 
  mutate(
    oddshprob = map_dbl(oddsh, convertodds),
    oddsdprob = map_dbl(oddsd, convertodds),
    oddsaprob = map_dbl(oddsa, convertodds),
    oddsprobtotal = oddshprob + oddsdprob + oddsaprob,
    probh = oddshprob / oddsprobtotal,
    probd = oddsdprob / oddsprobtotal,
    proba = oddsaprob / oddsprobtotal
  )

allodds %>% write_csv(here('data-get', 'oddsportal', 'processed', 'odds.csv'), na = '')

gamesbyseason = allodds %>% group_by(comp, season) %>% count()
gamesbyseason %>% write_csv(here('data-get', 'oddsportal', 'processed', 'season-game-counts.csv'), na = '')

teams = bind_rows(
  allodds %>% select(comp, team = teamh),
  allodds %>% select(comp, team = teama)
) %>% 
  mutate(team = str_trim(team)) %>% 
  group_by(team, comp) %>% 
  count() %>% 
  ungroup() %>% 
  mutate(comp = case_when(str_starts(comp, 'c') ~ 'cl', TRUE ~ 'el')) %>% 
  spread(comp, n) %>% 
  arrange(team)

teams

teams %>% write_csv(here('data-get','oddsportal','processed','team-names.csv'), na = '')
