library(here)
library(tidyverse)

summaries = read_csv(here('data-get', 'fbref', 'processed', 'match-urls.csv'))

missing = summaries %>% 
  mutate(szn = as.numeric(str_sub(szn, end = 4)) + 1) %>% 
  rename(season = szn) %>% 
  filter(season >= 2015) %>% 
  drop_na(stagecode) %>% 
  filter(is.na(hometeam1))

missingformatted = missing %>% 
  mutate(
    tieid = map2_chr(teamid1, teamid2, ~str_c(sort(c(.x, .y)), collapse = '|')),
    winner = team1,
    winnerid = teamid1,
    agr = str_detect(str_to_lower(result), 'away goals'),
    aet = str_detect(str_to_lower(result), 'extra time'),
    pk = str_detect(str_to_lower(result), 'penalty')
  ) %>% 
  select(
    season, stagecode, tieid, team1, team2, winner,
    teamid1, teamid2, winnerid,
    aggscore, result, agr, aet, pk
  )

missingformatted

missingformatted %>% 
  write_csv(here('data-get', 'assemble', 'missing-ties.csv'), na = '')

# 
# season stagecode tieid team1 team2 winner teamid1 teamid2 winnerid aggscore aggscore1 aggscore2 result score1 score2 t1win agr   aet   pk   
# <dbl> <chr>     <chr> <chr> <chr> <chr>  <chr>   <chr>   <chr>    <chr>    <chr>     <chr>     <chr>  <chr>  <chr>  <lgl> <lgl> <lgl> <lgl>
#   1   2015 cl-0q-1f… 112c… S.P.… Leva… Levad… 6de427… 112c96… 112c9642 0–8      0         8         Levad… 0–1    7–0    FALSE FALSE FALSE FALSE
# 2   2015 cl-0q-1f… 15c5… Red … Havn… Havna… 2d3c1b… 15c574… 15c5743b 3–6      3         6         Havna… 1–1    5–2    FALSE FALSE FALSE FALSE
# 3   2015 cl-0q-1f… 9549… Sant… FC B… Santa… 9549dc… f0e1ca… 9549dc95 3–3      3         3         Santa… 1–0    3–2    TRUE  TRUE  FALSE FALSE
# 4   2015 cl-0q-2s… 04c0… Sant… Macc… Macca… 9549dc… 04c011… 04c011d8 0–3      0         3         Macca… 0–1    2–0    FALSE FALSE FALSE FALSE
# 5   2015 cl-0q-2s… 112c… Spar… Leva… Spart… ecb862… 112c96… ecb862be 8–1      8         1         Spart… 7–0    1–1    TRUE  FALSE FALSE FALSE
# 6   2015 cl-0q-2s… 15c5… Part… Havn… Parti… dde3e8… 15c574… dde3e804 6–1      6         1         Parti… 3–0    1–3    TRUE  FALSE FALSE FALSE
# 7   2015 cl-0q-2s… 2a6c… Zrin… NK M… NK Ma… 2a6cfc… 2aae76… 2aae7689 0–2      0         2         NK Ma… 0–0    2–0    FALSE FALSE FALSE FALSE
# 8   2015 cl-0q-2s… 3f53… Vall… Qara… Qarab… 3f53cc… 44b654… 44b65410 0–5      0         5         Qarab… 0–1    4–0    FALSE FALSE FALSE FALSE
# 9   2015 cl-0q-2s… 488c… Ludo… F91 … Ludog… 488c6b… baae13… 488c6ba1 5–1      5         1         Ludog… 4–0    1–1    TRUE  FALSE FALSE FALSE
# 10   2015 cl-0q-2s… 4c64… Dina… Žalg… Dinam… edd0d3… 4c6489… edd0d381 4–0      4         0         Dinam… 2–0    0–2    TRUE  FALSE FALSE FALSE