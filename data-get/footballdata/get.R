library(httr)
library(tidyverse)

seasons = 2020:2001

getandsave <- function(comp, resource, szn) {
  destfile = str_c('data-get/footballdata/raw/', comp, '-', resource, '-', szn, '.json')
  if (!file.exists(destfile)) {
    req = GET(
      str_c('https://api.football-data.org/v2/competitions/', comp, '/', resource, '?season=', szn),
      add_headers('X-Auth-Token' = '87aa684e84a947daac79132d8180e2c0'))
    writeBin(content(req, 'raw'), destfile)
    print(str_c(destfile, ' downloaded'))
  } else {
    print(str_c(destfile, ' already exists'))
  }
}

getandsave('CL', 'matches', 2019)
getandsave('CL', 'teams', 2019)
