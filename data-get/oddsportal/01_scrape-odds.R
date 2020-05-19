library(here)
library(glue)
library(rvest)
library(tidyverse)
library(RSelenium)

# sudo docker run -d -p 4445:4444 selenium/standalone-firefox:3.141.59

runscrape = function(dr, lg, yr) {
  page = 1
  suffix = str_c('-', yr - 1, '-', yr, '/')
  if (yr == 2020) { suffix = '/' }
  if (lg == 'europa-league' & yr < 2010) { lgurl = 'uefa-cup'} else { lgurl = lg }
  
  outfolder = here('data-get', 'oddsportal', 'raw')
  # purge all of this year's files
  
  list.files(outfolder) %>% 
    str_c(outfolder, '/', .) %>% 
    `[`(str_detect(., glue('{lg}-{yr-1}-{yr}'))) %>% 
    file.remove()
  
  while (TRUE) {
    url = str_c('https://www.oddsportal.com/soccer/europe/', lgurl, suffix, 'results/#/page/', page, '/')
    print(str_c('going to ', url))
    dr$navigate(url)
    print(str_c('arrived at ', dr$getCurrentUrl()[[1]]))
    h = dr$getPageSource()[[1]] %>% read_html()
    tbldiv = h %>% html_node('div#tournamentTable')
    tbldivstyle = tbldiv %>% html_attr('style')
    while(tbldivstyle == 'display: none;') {
      print('table not visible, refreshing page')
      dr$refresh()
      Sys.sleep(3)
      h = dr$getPageSource()[[1]] %>% read_html()
      tbldiv = h %>% html_node('div#tournamentTable')
      tbldivstyle = tbldiv %>% html_attr('style')
    }
    print('table is visible')
    tbl = tbldiv %>% html_node('table#tournamentTable')
    empty = tbl %>% html_node('#emptyMsg')
    if(length(empty) != 0) {
      print('table has emptyMsg, breaking')
      break
    }
    fpath = str_c(lg, yr-1, yr, 'page', page, sep = '-') %>% str_c('.html')
    outpath = here('data-get', 'oddsportal', 'raw', fpath)
    write_html(h, outpath)
    print(str_c('wrote out ', fpath))
    page = page + 1
    Sys.sleep(1)
  }
}


lgs = c('champions-league', 'europa-league')
# yrs = 2020:2004
yrs = 2020
lgyr = expand.grid(lg = lgs, yr = yrs, stringsAsFactors = FALSE)

dr = remoteDriver(port = 4445L)
dr$open()

walk2(lgyr$lg, lgyr$yr, ~runscrape(dr, .x, .y))
