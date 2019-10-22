library(locfit)
library(tidyverse)

fits = read_rds('model/fits.rds')

fits

predictions = function(df, m) {
  df %>% 
    mutate(
      probwint1 = predict(m, newdata = df, type = 'response'),
      error = as.numeric(t1win) - probwint1,
      sqerror = error ^ 2
    )
}

preds = fits %>% 
  mutate(
    p1 = map2(testing, m1, predictions),
    p2 = map2(testing, m2, predictions),
    p3 = map2(testing, m3, predictions),
    p4 = map2(testing, m4, predictions),
  )

preds

sqerrors = preds %>% 
  mutate(
    p1error = map_dbl(p1, ~.x %>% pull(sqerror) %>% mean() %>% sqrt()),
    p2error = map_dbl(p2, ~.x %>% pull(sqerror) %>% mean() %>% sqrt()),
    p3error = map_dbl(p3, ~.x %>% pull(sqerror) %>% mean() %>% sqrt()),
    p4error = map_dbl(p4, ~.x %>% pull(sqerror) %>% mean() %>% sqrt())
  ) %>% 
  select(trial, starts_with('m'), ends_with('error'))
  


sqerrors

preds$p3[[1]] %>% count(t1win)

allpreds = preds %>%
  select(trial, starts_with('p')) %>% 
  gather(key = 'model', value = 'data', -trial) %>% 
  mutate(model = str_sub(model, start = -1)) %>% 
  unnest(cols = c(data))

allpreds

allpreds %>%
  group_by(model, minuteclean) %>% 
  summarise(rms = sqrt(mean(sqerror))) %>% 
  ggplot(aes(minuteclean, rms, color = model)) +
  geom_line() +
  scale_x_continuous(
    breaks = c(0, 45, 90, 135, 180, 210),
    labels = c('g1 start','g1 half','g1 end\ng2 start','g2 half','g2 end\net start','et end')
  ) +
  theme_minimal()

autocorr = allpreds %>% 
  mutate(probbin = cut(probwint1, breaks = 100)) %>%
  group_by(model, probbin) %>% 
  summarise(
    count = n(),
    prob = mean(probwint1),
    outcome = mean(t1win),
    outcomesd = sqrt(mean(prob * (1 - prob)) / length(prob))
  )

autocorr

autocorr %>% 
  ggplot(aes(prob, outcome)) +
  geom_abline(slope=1, color="red") +
  geom_point() +
  # geom_errorbar(aes(ymin = outcome - 2 * outcomesd, ymax = outcome + 2 * outcomesd), color="gray50") +
  facet_wrap(. ~ model) +
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