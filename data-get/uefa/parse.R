library(tidyverse)
library(pdftools)

pdf = pdf_text('data-get/uefa/raw/first_division_clubs_in_europe_2019_20.pdf')

pdfdata = pdf_data('data-get/uefa/raw/first_division_clubs_in_europe_2019_20.pdf')

teamsdata = pdfdata %>%
  keep(
    ~(.x %>% 
      filter(text %in% c('CLUB', 'COMMUNICATION')) %>%
      nrow()) == 2
  )
  

teams = pdf %>% 
  `[`(str_detect(str_to_upper(.), 'CLUB COMMUNICATION 2019/20')) %>% 
  tibble(text = .) %>% 
  mutate(text = map(text, str_split, pattern = '\n', simplify = TRUE))

teams

teams$text[[6]]

parsed = teams %>% 
  mutate(
    country = map_chr(
      text,
      ~.x %>%
        `[`(1) %>%
        str_split(' \\| ', simplify = TRUE) %>%
        `[`(1) %>%
        str_trim()
    )
  )

str(parsed)

parsed$text %>% map(~.x[-2])
