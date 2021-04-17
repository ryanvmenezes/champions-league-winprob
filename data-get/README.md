# Getting the data

All data on the match events comes from [fbref.com](https://fbref.com/). Betting market information comes from [oddsportal.com](https://www.oddsportal.com/).

Currently, this covers two competitions that both use two-legged ties and the away goals rule for certain stages of their competition: the UEFA Champions League and the UEFA Europa League (all matches except the group stages). It could likely be extended to other competitions, such as the CONMEBOL Copa Libertadores and more.

## Scraping match events

All scraping of fbref.com is done in R and uses a ["get or retrieve"](data-get/fbref/scrape-seasons.R#L13-L30) function that saves a raw copy of the entire targeted webpage on the first request, then accesses that copy on subsequent requests. This is intended to keep the number of requests to the website down and preserve the data for future access. The downside of this approach is that should the data on an already-accessed page change, it will need to be refetched.

TK: Use `override=TRUE` flag in function.

### 01_scrape-seasons.R

Crawls over the index pages for the CL and EL gathering info on the knockout round and qualifying round ties that need to be scraped for events, and the urls at which that information is stored.

*match-urls.csv*

| stagecode | competition | code_string | szn | stage | round | dates | team1 | team2 | teamid1 | teamid2 | winner | aggscore | result | hometeam1 | date1 | score1 | url1 | hometeam2 | date2 | score2 | url2 |
|:---------:|------------------|-------------|-----------|----------|------------|-------------------------------|-----------|-----------|----------|----------|-----------|----------|--------------------------------------------------------------|-----------|--------|--------|--------------------------------------------------------------------------------------------------|-----------|-------|--------|-----------------------------------------------------------------------------------------------|
|  | Champions League | cl | 2018-2019 | knockout | Final | June 1, 2019 | Liverpool | Tottenham | 822bd0ba | 361ca564 | Liverpool | 2–0 | Liverpool won match in normal time. |  |  |  |  |  |  |  |  |
| cl-1k-3sf | Champions League | cl | 2018-2019 | knockout | Semifinals | April 30, 2019 to May 8, 2019 | Tottenham | Ajax | 361ca564 | 19c3f8c4 | Tottenham | 3–3 | Tottenham won on away goals, after aggregate score was tied. | Tottenham | Apr 30 | 0–1 | https://fbref.com/en/matches/41848af6/Tottenham-Hotspur-Ajax-April-30-2019-UEFA-Champions-League | Ajax | May 8 | 2–3 | https://fbref.com/en/matches/09773f5a/Ajax-Tottenham-Hotspur-May-8-2019-UEFA-Champions-League |

### 02_scrape-games.R

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

### 03_scrape-teams.R

Creates an index of all teams listed by fbref.com and their countries, to join back to the data later. Can be run independently of the other scripts.

*fbref-all-teams.csv*

| country | countrycode2 | countrycode3 | governingbody | Squad | Gender | Comp | From | To | Comps | Champs | Other Names | clubid |
|---------|--------------|--------------|---------------|---------------------|--------|------|-----------|-----------|-------|--------|--------------|----------|
| Albania | al | ALB | UEFA | Besa Kavajë | M |  | 2010-2011 | 2010-2011 | 0 |  |  | 2fdee617 |
| Albania | al | ALB | UEFA | FK Kukësi | M |  | 2013-2014 | 2019-2020 | 0 |  |  | f1e85b1e |
| Albania | al | ALB | UEFA | FK Partizani Tirana | M |  | 2015-2016 | 2019-2020 | 0 |  | FK Partizani | 3ba2fddf |

## Scraping odds

The scraping of oddsportal.com is done in R using RSelenium. That requires first firing up a docker instance with a headless Firefox browser:

```bash
sudo docker run -d -p 4445:4444 selenium/standalone-firefox:3.141.59
```

### 01_scrape-odds.R

A lot of logic to scrape oddsportal pages, where the odds are not in the page body (they come via an XHR). Sometimes they don't show up at all! Messy code but it should capture most quirks. Dumps out just the raw HTML

### 02_parse-odds.R

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

# Assembling the data

A few relational tables need to be created with all of the requisite data. These will combine to form the predictors that will be fed into the model.

* teams: Unique team id, their name in the fbref data, the name in the oddsportal data and the country
* odds: A list of the odds for each leg of the tie
* summary: The summary of the two-legged ties. Who hosted each game, who won, did it go to ET, did it go to PKs, did the away goals rule apply, etc.
* events: The details of each match's events. Goals and red cards are labelled with a player's name and team.

## Reconcile differences in the team names

There are major variations between the oddsportal names and the fbref names. To ensure each team has a unique id, the fbref.com teams and ids are preferred.

### teams/01_reconcile-team-names.R

Start with the list of all of the CL/EL ties with data. Create a list of distinct fbref teams and ids. These often use "short names" or nicknames. Get the master name from fbref for each.

Bring in the list of all fbref teams from around the world. Join it against the distinct teams picked up by the scrape.

*europe-teams-fbref.csv*

| clubid | club | country | countrycode | governingbody | clubshortnames |
|----------|---------------------|------------|-------------|---------------|----------------|
| a224b06a | 1. FSV Mainz 05 | Germany | GER | UEFA | Mainz 05 |
| 7e746554 | Aalborg BK | Denmark | DEN | UEFA | Aalborg |
| 8bbab7cf | Aberdeen FC | Scotland | SCO | UEFA | Aberdeen |
| 6dbe9dca | Aberystwyth Town FC | Wales | WAL | UEFA | Aberystwyth |
| 633ae161 | AC Juvenes/Dogana | San Marino | SMR | UEFA | Juvenes/Dogana |

Get the distinct names from the oddsportal data.

## Create the odds table for the two-legged tie

The odds (of a home team win, an away team win or a draw) are listed by game. They need to be processed into a table that lists the odds by tie.

### odds/01_create-odds-table.R

## Create a summary file of all the ties

### summary/91_finding-missing-ties.R

Some of the data did not come with two complete game logs. Those ties need to be accounted for and scrapped from the data.

### summary/92_ties-with-invalid-games.R

Some ties have "invalid" games: Usually when a game was played, ended in a particular result, but later was forfeited. Sometimes this happens for a dramatic reason, like the time a game was abandoned because a player suffered a head injury when struck by a projectile hurled from the crowd.

### summary/00_find-extra-aet-ties.R

Sometimes fbref's result doesn't say "extra time" in it. This script finds the ties where the final aggregate score does not equal the score after 180 minutes. If the result doesn't say "extra time" we need to mark that before the summary is assembled.

### summary/01_compile-tie-summaries.R

This is the master summary of all the ties that will be used for predictions.

TK: Add countries to this table.

### events/01_inflate-events-table.R

The events of the match need to be "inflated" into a matrix that will be fed into the model. For each tie, a matrix needs to be constructed that goes from minute 1 to 180 (or minute 210 if there was extra time).
