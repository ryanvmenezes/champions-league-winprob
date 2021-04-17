library(tidyverse)
library(tidypredict)
library(glue)
library(yaml)
library(here)

this.version = 'v3'

source(here('model', 'utils.R'))

leg1 = read_rds(here('model', this.version, 'files', 'leg1.rds')) %>% 
  filter(season < test.season.cutoff)

leg2 = read_rds(here('model', this.version, 'files', 'leg2.rds')) %>% 
  filter(season < test.season.cutoff)

leg1

leg2

leg1models = leg1 %>% 
  distinct(minuteclean) %>% 
  mutate(
    data = map(
      minuteclean,
      ~{
        if (.x == 0 | .x == 180 | .x == 210) {
          filtered = leg1 %>% filter(minuteclean == .x)
        } else {
          filtered = leg1 %>% filter(minuteclean >= .x - 5 & minuteclean <= .x + 5)
        }
        filtered
      }
    ),
    model = map2(
      data, minuteclean,
      ~{
        formula = goals.left ~ goals.edge + prob.diff + away.goals.edge + men.edge + home
        if (.y == 0) {
          formula = goals.left ~ goals.edge + prob.diff + home
        }
        glm(
          formula = formula,
          data = .x,
          family = 'poisson'
        )
      }
    )
  )

leg1models

leg2models = leg2 %>% 
  distinct(minuteclean) %>% 
  mutate(
    data = map(
      minuteclean,
      ~{
        if (.x == 0 | .x == 180 | .x == 210) {
          filtered = leg2 %>% filter(minuteclean == .x)
        } else {
          filtered = leg2 %>% filter(minuteclean >= .x - 5 & minuteclean <= .x + 5)
        }
        filtered
      }
    ),
    model = map2(
      data, minuteclean,
      ~{
        formula = goals.left ~ goals.edge + prob.diff + away.goals.edge + men.edge + home
        if (.y == 0) {
          formula = goals.left ~ goals.edge + prob.diff + home
        } else if (.y <= 90) {
          formula = goals.left ~ goals.edge + prob.diff + away.goals.edge + home
        }
        glm(
          formula = formula,
          data = .x,
          family = 'poisson'
        )
      }
    )
  )

leg2models

# leg2models$model[[91]] %>% summary()

leg1models %>% 
  select(model, minuteclean) %>%
  pwalk(
    ~..1 %>% 
      parse_model() %>% 
      write_yaml(glue('model/v3/files/minute-models/leg-1-minute-{..2}.yaml'))
  )

leg2models %>% 
  select(model, minuteclean) %>%
  pwalk(
    ~..1 %>% 
      parse_model() %>% 
      write_yaml(glue('model/v3/files/minute-models/leg-2-minute-{..2}.yaml'))
  )
