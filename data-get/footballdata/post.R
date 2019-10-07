library(here)
library(httr)
library(tidyverse)

req = POST(
  str_c('http://fd-cluster-api-01.football-data.org:8080/v2/teams/?name=Barcelona'),
  add_headers('X-Auth-Token' = '87aa684e84a947daac79132d8180e2c0')
)
req
content(req) %>% str(max.level = 1)

content(req)$filters
content(req)$teams %>% str(max.level = 1)
content(req)$teams %>% `[[`(1)
tmp = read_rds('data/odds.rds')
