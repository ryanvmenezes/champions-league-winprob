# Win probability of two-legged ties in soccer

Win probability models are somewhat ubiquitous in sports analysis these days, with data used to describe the back-and-forth rhythm of a particular game. Less common are models that forecast the result of an aggregate outcome over multiple games. This is one attempt at that.

The model here aims to predict the winner in a specific kind of soccer competition: The [two-legged tie](https://en.wikipedia.org/wiki/Two-legged_tie). In such matchups, each team hosts one game (referred to as a "leg") and the winner is the team that scores the most goals over both games. This specifically focuses on competitions where the ["away goals rule"](https://en.wikipedia.org/wiki/Away_goals_rule) is used to break any deadlock. It started with a focus on the UEFA Champions League but has been extended further to cover the UEFA Europa League, and will hopefully be extended more.

## Abstract

All data on match events comes from [fbref.com](https://fbref.com/). Betting market information comes from [oddsportal.com](https://www.oddsportal.com/). The process of [scraping and assembling the data](data-get/README.md) is detailed in `data-get/README.md`.

The model is created using localized logistic regression, implemented using the `locfit` package in R. It takes a few inputs:

* The time remaining in the tie
* The goal difference between the two teams
* The away goal difference between the two teams
* The difference in the number red-carded players for a particular match
* The pre-match betting odds for the first leg of the tie

Those factors are used to spit out a probability that the team hosting the first leg will win the tie.

Plots charting the win probability according to the draft model can be found [here](model/plots/).

![](/model/plots/cl/2019/1k-1r16/Liverpool-Bayern%20Munich.png)

TK: How the model performs.
