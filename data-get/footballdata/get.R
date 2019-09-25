library(httr)
library(tidyverse)

seasons = 2020:2001

for (s in seasons) {
  comp = 'PL'
  req = GET(
    str_c('https://api.football-data.org/v2/competitions/', comp, '/matches?season=', s),
    add_headers('X-Auth-Token' = '87aa684e84a947daac79132d8180e2c0')
    )
  writeBin(content(req, 'raw'), str_c('data/footballdata/raw/', comp, '-', s, '.json'))
  print(str_c('done with ', s))
  Sys.sleep(10)
}
