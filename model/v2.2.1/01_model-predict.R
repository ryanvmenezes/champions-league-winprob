library(here)
library(tidyverse)

this.version = 'v2.2.1'

source(here('model', 'utils.R'))

models = training.data %>%
  distinct(minuteclean) %>%
  mutate(
    data = map(minuteclean, filter.by.minute),
    model = map(data, run.glm)
  ) %>%
  select(-data)

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

# "connect the dots" predictions

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
    filter(
      minuteclean == 1 |
        goalst1diff != lag(goalst1diff) |
        goalst1diff != lead(goalst1diff) |
        redcardst1diff != lead(redcardst1diff) |
        redcardst1diff != lag(redcardst1diff) |
        (!aet & minuteclean == 180) |
        minuteclean == 210
    ) %>% 
    ungroup()
  
  # apply linear smooth in between major jumps
  filtered.predictions %>% 
    select(predictedprobt1, minuteclean, minuterown) %>% 
    mutate(
      perminprobchg = (lead(predictedprobt1) - predictedprobt1) / (lead(minuterown) - minuterown)
    ) %>% 
    right_join(match.data, by = c('predictedprobt1', 'minuteclean', 'minuterown')) %>% 
    mutate(
      perminprobchg = lag(perminprobchg)
    ) %>% 
    fill(perminprobchg, .direction = 'down') %>% 
    mutate(
      perminprobchg = if_else(minuteclean == 1, predictedprobt1, perminprobchg),
      perminprobchg = cumsum(perminprobchg)
    ) %>% 
    select(
      t1win, probh1, probd1, proba1, minuteclean, minuterown, goalst1diff, awaygoalst1diff, redcardst1diff,
      player, playerid, eventtype, ag, predictedprobt1 = perminprobchg
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
