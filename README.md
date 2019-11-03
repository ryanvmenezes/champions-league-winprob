# Win probability of two-legged ties in soccer

Win probability models are somewhat ubiquitous in sports analysis these days, with data used to describe the back-and-forth rhythm of a particular game. Less common are models that forecast the result of an aggregate outcome over multiple games. This is one attempt at that.

The model here aims to predict the winner in a specific kind of soccer competition: The [two-legged tie](https://en.wikipedia.org/wiki/Two-legged_tie). In such matchups, each team hosts one game (referred to as a "leg") and the winner is the team that scores the most goals over both games. This specifically focuses on competitions where the ["away goals rule"](https://en.wikipedia.org/wiki/Away_goals_rule) is used to break any deadlock.

## Abstract of the model

The model is created using localized logistic regression, implemented using the `locfit` package in R. It takes a few inputs:

* The time remaining in the tie
* The goal difference between the two teams
* The away goal difference between the two teams
* The difference in the number red-carded players for a particular match
* The pre-match betting odds for the first leg of the tie

Those factors are used to spit out a probability that the team hosting the first leg will win the tie.

Currently, this covers two competitions that both use two-legged ties and the away goals rule for certain stages of their competition: the UEFA Champions League and the UEFA Europa League. It could likely be extended to other competitions, suchs as the CONMEBOL Copa Libertadores and more.

## Getting the data

All data on the match events comes from [fbref.com](https://fbref.com/). Betting market information comes from [oddsportal.com](http://oddsportal.com/).

### Scraping match events

This starts by scraping the games we need to analyze. 


| stagecode | competition | code_string | szn | stage | round | dates | team1 | team2 | teamid1 | teamid2 | winner | aggscore | result | hometeam1 | date1 | score1 | url1 | hometeam2 | date2 | score2 | url2 |
|:---------:|:----------------:|-------------|-----------|----------|---------------|---------------------------------|-----------|-----------------|----------|----------|-----------|----------|--------------------------------------------------------------|-----------|--------|--------|------------------------------------------------------------------------------------------------------------|-----------------|--------|--------|-------------------------------------------------------------------------------------------------------------|
|  | Champions League | cl | 2018-2019 | knockout | Final | June 1, 2019 | Liverpool | Tottenham | 822bd0ba | 361ca564 | Liverpool | 2–0 | Liverpool won match in normal time. |  |  |  |  |  |  |  |  |
| cl-1k-3sf | Champions League | cl | 2018-2019 | knockout | Semifinals | April 30, 2019 to May 8, 2019 | Tottenham | Ajax | 361ca564 | 19c3f8c4 | Tottenham | 3–3 | Tottenham won on away goals, after aggregate score was tied. | Tottenham | Apr 30 | 0–1 | https://fbref.com/en/matches/41848af6/Tottenham-Hotspur-Ajax-April-30-2019-UEFA-Champions-League | Ajax | May 8 | 2–3 | https://fbref.com/en/matches/09773f5a/Ajax-Tottenham-Hotspur-May-8-2019-UEFA-Champions-League |
| cl-1k-3sf | Champions League | cl | 2018-2019 | knockout | Semifinals | April 30, 2019 to May 8, 2019 | Liverpool | Barcelona | 822bd0ba | 206d90db | Liverpool | 4–3 | Liverpool won on aggregate score over two legs. | Barcelona | May 1 | 3–0 | https://fbref.com/en/matches/b45b35c3/Barcelona-Liverpool-May-1-2019-UEFA-Champions-League | Liverpool | May 7 | 4–0 | https://fbref.com/en/matches/20b882b6/Liverpool-Barcelona-May-7-2019-UEFA-Champions-League |
| cl-1k-2qf | Champions League | cl | 2018-2019 | knockout | Quarterfinals | April 9, 2019 to April 17, 2019 | Tottenham | Manchester City | 361ca564 | b8fd03ef | Tottenham | 4–4 | Tottenham won on away goals, after aggregate score was tied. | Tottenham | Apr 9 | 1–0 | https://fbref.com/en/matches/ecf6dedc/Tottenham-Hotspur-Manchester-City-April-9-2019-UEFA-Champions-League | Manchester City | Apr 17 | 4–3 | https://fbref.com/en/matches/5a2a056f/Manchester-City-Tottenham-Hotspur-April-17-2019-UEFA-Champions-League |
| cl-1k-2qf | Champions League | cl | 2018-2019 | knockout | Quarterfinals | April 9, 2019 to April 17, 2019 | Liverpool | Porto | 822bd0ba | 5e876ee6 | Liverpool | 6–1 | Liverpool won on aggregate score over two legs. | Liverpool | Apr 9 | 2–0 | https://fbref.com/en/matches/1ff096ec/Liverpool-Porto-April-9-2019-UEFA-Champions-League | Porto | Apr 17 | 1–4 | https://fbref.com/en/matches/1ab1a0b0/Porto-Liverpool-April-17-2019-UEFA-Champions-League |