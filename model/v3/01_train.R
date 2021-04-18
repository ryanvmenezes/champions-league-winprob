library(tidyverse)
library(tidypredict)
library(glue)
library(yaml)

train = read_rds('model/v3/predictors/train.rds')

train

models = train %>% 
  distinct(leg, minuteclean) %>% 
  mutate(
    data = map2(
      minuteclean, leg,
      ~{
        if (.x == 0 | .x == 180 | .x == 210) {
          filtered = train %>% filter(leg == .y, minuteclean == .x)
        } else {
          filtered = train %>% filter(leg == .y, minuteclean >= .x - 5, minuteclean <= .x + 5)
        }
        filtered
      }
    ),
    model = pmap(
      list(leg, minuteclean, data),
      ~{
        formula = goals.left ~ prob.diff + goals.edge + away.goals.edge + players.edge + home
        if (..1 == 2 & ..2 <= 90) {
          formula = goals.left ~ prob.diff + goals.edge + away.goals.edge + home
        }
        if (..2 == 0) {
          formula = goals.left ~ prob.diff + home
        }
        glm(
          formula = formula,
          data = ..3,
          family = 'poisson'
        )
      }
    )
  )

models

models %>%
  select(leg, minuteclean, model) %>%
  pwalk(
    ~..3 %>%
      parse_model() %>%
      write_yaml(glue('model/v3/models/leg-{..1}-minute-{..2}.yaml'))
  )