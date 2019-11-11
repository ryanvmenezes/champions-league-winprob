# Win probability of two-legged ties in soccer

Win probability models are somewhat ubiquitous in sports analysis these days, with data used to describe the back-and-forth rhythm of a particular game. Less common are models that forecast the result of an aggregate outcome over multiple games. This is one attempt at that.

The model here aims to predict the winner in a specific kind of soccer competition: The [two-legged tie](https://en.wikipedia.org/wiki/Two-legged_tie). In such matchups, each team hosts one game (referred to as a "leg") and the winner is the team that scores the most goals over both games. This specifically focuses on competitions where the ["away goals rule"](https://en.wikipedia.org/wiki/Away_goals_rule) is used to break any deadlock.

- [Abstract of the model](#abstract-of-the-model)
- [Getting the data](#getting-the-data)
  * [Scraping match events](#scraping-match-events)
    + [01_scrape-seasons.R](#01-scrape-seasonsr)
    + [02_scrape-games.R](#02-scrape-gamesr)
    + [03_scrape-teams.R](#03-scrape-teamsr)
  * [Scraping odds](#scraping-odds)
    + [01_scrape-odds.R](#01-scrape-oddsr)
    + [02_parse-odds.R](#02-parse-oddsr)
- [Assembling the data](#assembling-the-data)

## Abstract of the model

The model is created using localized logistic regression, implemented using the `locfit` package in R. It takes a few inputs:

* The time remaining in the tie
* The goal difference between the two teams
* The away goal difference between the two teams
* The difference in the number red-carded players for a particular match
* The pre-match betting odds for the first leg of the tie

Those factors are used to spit out a probability that the team hosting the first leg will win the tie.

TK: How the model performs.

## Getting the data

All data on the match events comes from [fbref.com](https://fbref.com/). Betting market information comes from [oddsportal.com](http://oddsportal.com/).

Currently, this covers two competitions that both use two-legged ties and the away goals rule for certain stages of their competition: the UEFA Champions League and the UEFA Europa League (all matches except the group stages). It could likely be extended to other competitions, such as the CONMEBOL Copa Libertadores and more.

### Scraping match events

All scraping of fbref.com is done in R and uses a ["get or retrieve"](data-get/fbref/scrape-seasons.R#L13-L30) function that saves a raw copy of the entire targeted webpage on the first request, then accesses that copy on subsequent requests. This is intended to keep the number of requests to the website down and preserve the data for future access. The downside of this approach is that should the data on an already-accessed page change, it will need to be refetched.

TK: Use `override=TRUE` flag in function.

#### 01_scrape-seasons.R

Crawls over the index pages for the CL and EL gathering info on the knockout round and qualifying round ties that need to be scraped for events, and the urls at which that information is stored.

*match-urls.csv*

| stagecode | competition | code_string | szn | stage | round | dates | team1 | team2 | teamid1 | teamid2 | winner | aggscore | result | hometeam1 | date1 | score1 | url1 | hometeam2 | date2 | score2 | url2 |
|:---------:|------------------|-------------|-----------|----------|------------|-------------------------------|-----------|-----------|----------|----------|-----------|----------|--------------------------------------------------------------|-----------|--------|--------|--------------------------------------------------------------------------------------------------|-----------|-------|--------|-----------------------------------------------------------------------------------------------|
|  | Champions League | cl | 2018-2019 | knockout | Final | June 1, 2019 | Liverpool | Tottenham | 822bd0ba | 361ca564 | Liverpool | 2–0 | Liverpool won match in normal time. |  |  |  |  |  |  |  |  |
| cl-1k-3sf | Champions League | cl | 2018-2019 | knockout | Semifinals | April 30, 2019 to May 8, 2019 | Tottenham | Ajax | 361ca564 | 19c3f8c4 | Tottenham | 3–3 | Tottenham won on away goals, after aggregate score was tied. | Tottenham | Apr 30 | 0–1 | https://fbref.com/en/matches/41848af6/Tottenham-Hotspur-Ajax-April-30-2019-UEFA-Champions-League | Ajax | May 8 | 2–3 | https://fbref.com/en/matches/09773f5a/Ajax-Tottenham-Hotspur-May-8-2019-UEFA-Champions-League |

#### 02_scrape-games.R

Starts by filtering the two-legged ties set down to just ones that have detailed match data. For both the CL and EL this is from the 2014-15 season until now. Also cleans up the summaries to follow a standard convention:

* The ties are given an id of the form `teamid1|teamid2` where **the ids are sorted alphabetically**.
* In the detailed breakdown, **`team1` is always the team that hosted the first leg**.

*two-legged-ties.csv*

| szn | stagecode | tieid | team1 | team2 | winner | teamid1 | teamid2 | winnerid | aggscore | result | score1 | score2 |
|:---------:|------------|-------------------|--------------|------------------|------------------|----------|----------|----------|----------|--------------------------------------------------------------------------------------------------------|--------|--------|
| 2014-2015 | cl-0q-1fqr | 9549dc95\|f0e1ca42 | Santa Coloma | FC Banants | Santa Coloma | 9549dc95 | f0e1ca42 | 9549dc95 | 3–3 | Santa Coloma won on away goals, after aggregate score was tied and advance to Second Qualifying Round. | 1–0 | 3–2 |
| 2014-2015 | cl-0q-1fqr | 15c5743b\|2d3c1b6d | Red Imps | Havnar Bóltfelag | Havnar Bóltfelag | 2d3c1b6d | 15c5743b | 15c5743b | 3–6 | Havnar Bóltfelag won on aggregate score over two legs and advance to Second Qualifying Round. | 1–1 | 5–2 |

Then crawls over the urls for each game and extracts the match events.

*match-events.csv*

| szn | stagecode | tieid | teamid1 | teamid2 | leg | score | player | playerid | eventtype | minute | team |
|:---------:|-----------|-------------------|----------|----------|-----|-------|---------------------|----------|-----------|--------|------|
| 2018-2019 | cl-1k-3sf | 206d90db|822bd0ba | 206d90db | 822bd0ba | 1 | 3–0 | Luis Suárez | a6154613 | goal | 26 | 1 |
| 2018-2019 | cl-1k-3sf | 206d90db|822bd0ba | 206d90db | 822bd0ba | 1 | 3–0 | Lionel Messi | d70ce98e | goal | 75 | 1 |
| 2018-2019 | cl-1k-3sf | 206d90db|822bd0ba | 206d90db | 822bd0ba | 1 | 3–0 | Lionel Messi | d70ce98e | goal | 82 | 1 |
| 2018-2019 | cl-1k-3sf | 206d90db|822bd0ba | 206d90db | 822bd0ba | 2 | 4–0 | Divock Origi | 43a166b4 | goal | 7 | 1 |
| 2018-2019 | cl-1k-3sf | 206d90db|822bd0ba | 206d90db | 822bd0ba | 2 | 4–0 | Georginio Wijnaldum | eb58eef0 | goal | 54 | 1 |
| 2018-2019 | cl-1k-3sf | 206d90db|822bd0ba | 206d90db | 822bd0ba | 2 | 4–0 | Georginio Wijnaldum | eb58eef0 | goal | 56 | 1 |
| 2018-2019 | cl-1k-3sf | 206d90db|822bd0ba | 206d90db | 822bd0ba | 2 | 4–0 | Divock Origi | 43a166b4 | goal | 79 | 1 |

#### 03_scrape-teams.R

Creates an index of all teams listed by fbref.com and their countries, to join back to the data later. Can be run independently of the other scripts.

*fbref-all-teams.csv*

| country | countrycode2 | countrycode3 | governingbody | Squad | Gender | Comp | From | To | Comps | Champs | Other Names | clubid |
|---------|--------------|--------------|---------------|---------------------|--------|------|-----------|-----------|-------|--------|--------------|----------|
| Albania | al | ALB | UEFA | Besa Kavajë | M |  | 2010-2011 | 2010-2011 | 0 |  |  | 2fdee617 |
| Albania | al | ALB | UEFA | FK Kukësi | M |  | 2013-2014 | 2019-2020 | 0 |  |  | f1e85b1e |
| Albania | al | ALB | UEFA | FK Partizani Tirana | M |  | 2015-2016 | 2019-2020 | 0 |  | FK Partizani | 3ba2fddf |

### Scraping odds

The scraping of oddsportal.com is done in R using RSelenium. That requires first firing up a docker instance with a headless Firefox browser:

```bash
sudo docker run -d -p 4445:4444 selenium/standalone-firefox:3.141.59
```

#### 01_scrape-odds.R

A lot of logic to scrape oddsportal pages, where the odds are not in the page body (they come via an XHR). Sometimes they don't show up at all! Messy code but it should capture most quirks. Dumps out just the raw HTML

#### 02_parse-odds.R

Goes through the HTML of each page to create one massive odds file. Listed American odds (-250, +500, etc.) are converted into implied probability, then a vig-free probability.

*odds.csv*

| comp | season | page | round | date | teamh | teama | scoreh | scorea | oddsh | oddsd | oddsa | pens | awarded | extratime | cancelled | oddshprob | oddsdprob | oddsaprob | oddsprobtotal | probh | probd | proba |
|------------------|--------|------|-----------|------------|---------|----------|--------|--------|-------|-------|-------|-------|---------|-----------|-----------|-------------------|-------------------|-------------------|------------------|-------------------|-------------------|-------------------|
| champions-league | 2004 | 1 | Play Offs | 2004-05-26 | Monaco | FC Porto | 0 | 3 | 192 | 202 | 131 | FALSE | FALSE | FALSE | FALSE | 0.342465753424657 | 0.33112582781457 | 0.432900432900433 | 1.10649201413966 | 0.309505851870913 | 0.299257313729492 | 0.391236834399595 |
| champions-league | 2004 | 1 | Play Offs | 2004-05-05 | Chelsea | Monaco | 2 | 2 | -154 | 231 | 392 | FALSE | FALSE | FALSE | FALSE | 0.606299212598425 | 0.302114803625378 | 0.203252032520325 | 1.11166604874413 | 0.545396896202213 | 0.271767590605725 | 0.182835513192063 |

Also generates a list of team names in the data, which need to be manually reconciled with the fbref team names.

*team-names.csv*

| team | cl | el |
|----------------|----|----|
| Aalborg | 10 | 26 |
| Aalborg (Den) | 4 | 2 |
| Aalesund |  | 2 |
| Aalesund (Nor) |  | 12 |
| Aarhus (Den) |  | 2 |

## Assembling the data



