library(here)
library(locfit)
library(tidyverse)

model = read_rds(here('model', 'final-model.rds'))


getpredictions = function(df, m) {
  df %>% 
    mutate(
      probwint1 = predict(m, newdata = df, type = 'response'),
      error = as.numeric(t1win) - probwint1,
      sqerror = error ^ 2
    )
}

eval = fits %>% 
  mutate(
    predictions = map2(testing, fittedmodel, getpredictions),
    rmserror = map_dbl(predictions, ~.x %>% pull(sqerror) %>% mean() %>% sqrt())
  )

eval

eval$predictions[[6]] %>% View()

eval %>% 
  select(modelno, modelname, trial, rmserror) %>% 
  arrange(rmserror)

eval %>% 
  select(modelno, modelname, trial, rmserror) %>% 
  arrange(rmserror) %>% 
  spread(trial, rmserror)

allpreds = eval %>%
  select(modelno, modelname, predictions) %>% 
  unnest(cols = c(predictions))

allpreds

allpreds %>%
  group_by(modelname, minuteclean) %>% 
  summarise(rms = sqrt(mean(sqerror))) %>% 
  ggplot(aes(minuteclean, rms, color = modelname)) +
  geom_line() +
  scale_x_continuous(
    breaks = c(0, 45, 90, 135, 180, 210),
    labels = c('g1 start','g1 half','g1 end\ng2 start','g2 half','g2 end\net start','et end')
  ) +
  theme_minimal()

autocorr = allpreds %>% 
  mutate(probbin = cut(probwint1, breaks = 100)) %>%
  group_by(modelname, probbin) %>% 
  summarise(
    count = n(),
    actualwins = sum(t1win),
    calcwins = sum(probwint1),
    prob = mean(probwint1),
    outcome = mean(t1win),
    # outcomesd = sqrt(mean(outcome * (1 - outcome)) / length(outcome))
  )

autocorr

autocorr %>% 
  ggplot(aes(prob, outcome)) +
  geom_abline(slope=1, color="red") +
  geom_point() +
  # geom_errorbar(aes(ymin = outcome - 2 * outcomesd, ymax = outcome + 2 * outcomesd), color="gray50") +
  facet_wrap(. ~ modelname) +
  theme_minimal()


calibrationPlot <- function(prob, outcome, bins=100) {
  prob.bins <- cut(prob, unique(quantile(prob, seq(0, 1, l=bins+1))))
  prob.means <- tapply(prob, prob.bins, mean)
  outc.means <- tapply(outcome, prob.bins, mean)
  outc.sd <- tapply(prob, prob.bins, function(p) sqrt(mean(p * (1- p)) / length(p)))
  df <- data.frame(prob.means, outc.means, outc.sd)
  
  ggplot(df, aes(x = prob.means, y = outc.means)) +
    geom_abline(slope=1, color="red", lwd=2) +
    geom_point(size = 2) +
    geom_errorbar(aes(ymin = outc.means - 2 * outc.sd, ymax = outc.means + 2 * outc.sd), color="gray50") +
    labs(x="predicted win prob", y="observed win %") +
    lims(x=c(0, 1), y=c(0, 1)) +
    theme(plot.title = element_text(size=16, hjust = 0.5)) +
    theme(axis.text=element_text(size=14), axis.title=element_text(size=16))
}