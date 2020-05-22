library(tidyverse)

invalidties = tribble(
  ~season, ~stagecode, ~tieid, ~reason,
  2015, 'cl-0q-3tqr', 'a73408a7|b81aa4fa', 'Warsaw fielded ineligible player (https://www.theguardian.com/football/2014/aug/08/celtic-reinstated-champions-league-uefa-legia-warsaw)',
  2016, 'el-0q-3tqr', 'a73408a7|f1e85b1e', 'Kukeski home leg abandoned (https://www.theguardian.com/football/2015/aug/04/legia-warsaw-winners-kukesi-abandoned-europa-league-qualifier)'
)

invalidties

invalidties %>% write_csv(here('data-get', 'assemble', 'summary', 'invalid-ties.csv'))
