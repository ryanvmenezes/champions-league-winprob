library(rvest)
library(tidyverse)
library(RSelenium)

# sudo docker run -d -p 4445:4444 selenium/standalone-firefox:3.141.59

remDr <- remoteDriver(
  remoteServerAddr = "localhost",
  port = 4445L,
  browserName = "firefox"
)
remDr$open()
remDr$getStatus()
remDr$navigate('https://www.oddsportal.com/soccer/europe/champions-league-2018-2019/results/')

src = remDr$getPageSource()
src[[1]] %>%
  read_html() %>% 
  html_node('table#tournamentTable') %>% 
  html_table() %>%
  View()
