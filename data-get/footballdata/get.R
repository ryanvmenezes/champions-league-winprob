library(here)
library(httr)
library(tidyverse)

getandsave <- function(comp, resource, szn, delay = 2) {
  fname = str_c(comp, '-', resource, '-', szn, '.json')
  destfile = here('data-get', 'footballdata', 'raw', fname)
  if (!file.exists(destfile)) {
    req = GET(
      str_c('https://api.football-data.org/v2/competitions/', comp, '/', resource, '?season=', szn),
      add_headers('X-Auth-Token' = '87aa684e84a947daac79132d8180e2c0'))
    writeBin(content(req, 'raw'), destfile)
    print(str_c(fname, ' downloaded'))
    Sys.sleep(delay)
  } else {
    print(str_c(fname, ' already exists'))
  }
}

leagues = c('CL', 'EL')
resources = c('matches','teams','standings')
seasons = 2019:2015

allrequests = expand.grid(
  comp = leagues,
  resource = resources,
  szn = seasons,
  stringsAsFactors = FALSE
  )

pwalk(allrequests, getandsave)
