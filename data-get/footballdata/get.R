library(httr)
library(tidyverse)

seasons = 2016:2001

for (s in seasons) {
  req = GET(
    str_c('https://api.football-data.org/v2/competitions/CL/matches?season=', s),
    add_headers('X-Auth-Token' = '87aa684e84a947daac79132d8180e2c0')
    )
  writeBin(content(req, 'raw'), str_c('data/footballdata/raw/', s, '.json'))
  print(str_c('done with ', s))
  Sys.sleep(10)
}
