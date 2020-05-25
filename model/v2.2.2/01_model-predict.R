library(here)
library(tidyverse)

this.version = 'v2.2.2'

source(here('model', 'utils.R'))

models = training.data %>%
  distinct(minuteclean) %>%
  mutate(
    data = map(minuteclean, filter.by.minute),
    model = map(data, run.glm)
  ) %>%
  select(-data)

models

predictions = models %>%
  mutate(
    predictions = map2(
      model,
      minuteclean,
      ~make.predictions(
        .x,
        data = all.data %>% filter(minuteclean == .y)
      )
    )
  ) %>%
  select(-model, -minuteclean) %>%
  unnest(c(predictions)) %>%
  arrange(season, stagecode, tieid)

predictions

# "connect the dots" by smoothly averaging, not linear interpolation

# 2017 el-1k-2r16 0f9294bd|2fdb4aef Olympiacos   Beşiktaş 

# match.data = nested.predictions %>% 
#   filter(season == 2019, tieid == '017bcbe4|56b45f69') %>% 
#   pull(data) %>% 
#   `[[`(1)
# 
# match.data

adjust.match.predictions = function(match.data) {
  # filter down to before/after key events
  filtered.predictions = match.data %>% 
    # assign probability at 180 UNLESS it's aet
    mutate(
      predictedprobt1 = case_when(
        minuteclean == 180 & !aet ~ as.numeric(t1win),
        minuteclean == 210 & !pk ~ as.numeric(t1win),
        TRUE ~ predictedprobt1
      )
    ) %>% 
    mutate(
      key.moment = case_when(
        minuteclean == 1 |
          goalst1diff != lag(goalst1diff) |
          goalst1diff != lead(goalst1diff) |
          redcardst1diff != lead(redcardst1diff) |
          redcardst1diff != lag(redcardst1diff) |
          (!aet & minuteclean == 180) |
          minuteclean == 210 ~ TRUE,
        TRUE ~ FALSE
      ),
      key.moment.group = cumsum(key.moment)
    ) %>% 
    ungroup() %>% 
    group_by(key.moment.group) %>% 
    nest() %>% 
    mutate(
      data = map(
        data,
        ~.x %>% 
          mutate(
            predictedprobt1smooth = zoo::rollapplyr(predictedprobt1, width = 3, FUN = mean,  partial = TRUE),
          )
      )
    ) %>% 
    ungroup() %>% 
    select(-key.moment.group) %>% 
    unnest(c(data)) %>% 
    select(
      t1win, probh1, probd1, proba1, minuteclean, minuterown, goalst1diff, awaygoalst1diff, redcardst1diff,
      player, playerid, eventtype, ag, predictedprobt1 = predictedprobt1smooth
    )
}

nested.predictions = predictions %>% 
  left_join(
    summaries %>% 
      select(season, stagecode, tieid, aet, pk),
    by = c("season", "stagecode", "tieid")
  ) %>% 
  group_by(season, stagecode, tieid) %>% 
  nest() %>% 
  mutate(new.predictions = map(data, adjust.match.predictions))

nested.predictions

predictions.new = nested.predictions %>% 
  select(-data) %>% 
  unnest(c(new.predictions)) %>% 
  mutate(
    likelihood = case_when(
      t1win == FALSE ~ 1 - predictedprobt1,
      t1win == TRUE ~ predictedprobt1
    ),
    error = as.numeric(t1win) - predictedprobt1,
    sqerror = error ^ 2
  )

predictions.new

save.predictions(predictions.new, this.version)
