Welcome to __tiepredict__. This website serves as the home of the results of a win probability model for European club football created by me, [Ryan Menezes](https://ryanvmenezes.github.io/about/), a data analyst and coder based in America growing increasingly obsessed with the sport.

The model aims to forecast the outcome in a specific kind of contest: One where each team plays a home match, and the winner is determined by the total number of goals scored across the two matches. This is referred to as a [two-legged tie](https://en.wikipedia.org/wiki/Two-legged_tie), hence __tie__predict. (We might call such matchups a home-and-away series in America, where the term "tie" is mainly used to refer to a game where the score ends level, an outcome more typically referred to as a "draw" in the rest of the world. Luckily there's absolute harmony across the world when it comes to what to call the sport that is the focus of this project.)

More details will follow in this post but here's a brief summary of how this project came together: Using the R programming language, I started by scraping match information from [FBref](https://fbref.com/en/), a burgeoning resource for global soccer statistics. I also scraped data on the betting odds of each match from [OddsPortal](https://www.oddsportal.com/soccer/europe/champions-league/) to assess the relative strength of each team. After organizing and combining the data, I attempted some predictive modeling in R to forecast the winner of the tie. Once I felt comfortable with the predictions I was getting, I created this website to publish hundreds of [win](/tiepredict/ties/2017-cl-1k-3r16-sevilla-leicester-city/) [probability](/tiepredict/ties/2016-cl-0q-1fqr-red-imps-santa-coloma/) [charts](/tiepredict/ties/2019-el-0q-1fqr-cs-fola-esch-fc-prishtina/).

I focused specifically on matches where the [away goals rule](https://en.wikipedia.org/wiki/Away_goals_rule) applies. I am endlessly fascinated by this rule. There is no equivalent that I know of in American sports, where all points, goals or runs are inherently equal. It adds a layer of distortion I'm still not totally comfortable with: I see a 2-2 score and my mind thinks it's an even contest, but I also know that's not the case.

Right now, this project covers matches in UEFA's Champions League and Europa League. It will hopefully be expanded to include other competitions, such as the UEFA Women's Champions League and CONMEBOL's Copa Libertadores, as I gather more data. It is also not live-updating, but maybe will be in the future if I can ever figure that out. For now, interested parties will have to wait until I can hit a button on my computer to grab the latest data. 

What follows is a more long-winded explanation of my motivations and details of how this came together. If you have any questions, feel free to [contact me](mailto:ryanvmenezes@gmail.com). I would love to chat more about this project and appreciate any feedback. Thanks for checking it out.

_--Ryan_

## Why did I do this?

As I mentioned earlier, I'm a relative newcomer to soccer, having picked up watching the sport around 2015 after an upbringing spent immersed in the most popular American sports. Now, I set alarms for weekend mornings so I can wake up to watch England's Premier League, and any other interesting European matches for which I have time. Having started watching just a few years ago, I feel like I have a lot of catching up to do. And when it comes time to doing any research, for my job or otherwise, I turn to data as much as I can.

I was also motivated to learn more about the world of football beyond Europe's most glamorous continental matches. Many people start watching the Champions League around the 32-team group stage, but the competition has really been going on for months before that, involving dozens more teams. The champion from each of Europe's domestic leagues gets a spot in the tournament, even tiny [Gibraltar](/tiepredict/ties/2017-cl-0q-1fqr-fc-flora-red-imps/). Then there's the Europa League, which commands far fewer attention but globally but has always captivated me. It's mostly free of big-monied teams (and even includes the random [college team](/tiepredict/ties/2020-el-0q-0pre-progres-cardiff-met/)), which makes for more competitive matches, oftentimes in remote parts of the world I can only imagine. Whether it was the Champions League or Europa League, knockout rounds or qualifying rounds, I wanted to take a holistic view of the data.

Win probability models, which are somewhat ubiquitous in sports these days, have also long fascinated me. My undergraduate degree was in statistics, and while predictive modeling has never been my strong suit, I immediately saw that win probability was just a type of model. It asks a simple question: Who will win the game? And it uses a number of inputs about the game to estimate each team's chances. These days, ESPN puts win probability charts [alongside box scores](https://www.espn.com/nba/game/_/gameId/401307677) of most sports (though not soccer matches). But I had not seen a model specifically meant to chart the outcome of a two-legged tie.

So I wanted to do this to pique my statistical interests, but also because I see a win probability chart as telling a _story_. As a journalist, I'm interested in good stories, and I think that these charts provide a distillation of the many complicated factors in a particular game. I wouldn't stare at a live win probability chart instead of watching a game or anything, but if I'm trying to get a broad overview of what went on in a game, I check how the win probability fluctuated. And as I mentioned before, I'm playing catchup here with football.

So far, I've unearthed some interesting stories that I previously missed. Many people probably watched Barcelona's [remarkable comeback](/tiepredict/ties/2017-cl-1k-3r16-paris-s-g-barcelona/) against Paris Saint-Germain in 2017. But far fewer were tuned in when a tiny Maltese side named Gżira United [stunned](/tiepredict/ties/2020-el-0q-1fqr-gzira-united-hajduk-split/) a much more established Croatian team early in Europa League qualifying in 2019, a feat my model rates as [the greatest comeback](/tiepredict/ties/comeback/) out of the more than 1,400 matches I've gathered data for. You can [see the sheer joy](https://www.youtube.com/watch?v=zfDeZs_WBSY) on the face of the Gżira's Ivorian striker, whose two spectacular goals in Croatia led his team to a win on away goals. This might be the pinnacle of that player's career and [the best night ever for his club](https://timesofmalta.com/articles/view/we-made-history-gzira-knock-out-hajduk-split-in-europa-league.722890). This win probability model is one way of capturing it.

## Where do the data come from?

Primarily from the two sources mentioned above: FBref and Odds Portal.

The first thing I needed to do this was the basic information on how the match went. Namely, when the goals were scored (and to a lesser extent, when any player was red carded, if any). I examined a few sources for match data, including Wikipedia, which presents information in [neat tables](https://en.wikipedia.org/wiki/2018%E2%80%9319_UEFA_Champions_League_knockout_phase#Round_of_16). I found FBref data to be clean, authoritative and comprehensive when it came to the two [European](https://fbref.com/en/comps/8/Champions-League-Stats) [competitions](https://fbref.com/en/comps/19/Europa-League-Stats), so I settled on their data as my source.

I also needed some indication of how strong each team was. It would be foolish to think that any tie starts as a coin flip. While American sports leagues have instituted measures to enhance competitive balance (or, alternatively, to save owners money) European soccer games often showcase massive inequities between the teams. But how best to get at that difference? I turned to the betting odds. This is not a perfect measure: Oddsmakers are not trying to assess each team's strength. Rather, they are trying to find a set of odds that encourage equal an equal amount of betting on each outcome, to diversify their risk. Still, betting odds remain very predictive of future outcomes. I settled on using Odds Portal because it has a complete archive of odds for matches from all over the world. Perhaps, in the future I could use a more objective measure, like [FiveThirtyEight's club ratings](https://projects.fivethirtyeight.com/global-club-soccer-rankings/), or build a rating system on my own.

(There were a handful of qualifying matches which did not have odds data. For those matches, I assumed there was no difference in the teams, which led to another interesting discovery: even if teams are of equal strength, the tie is typically not a coin flip. The team hosting the second leg [starts with a 65% chance of winning](/tiepredict/ties/2016-cl-0q-3tqr-maccabi-tel-aviv-viktoria-plzen/).)

After downloading the data, a large amount of cleaning, parsing and joining was required to get the tables I needed. If you see an error somewhere in the site, it's likely my fault and not that of the source data.

## How does the model work?

I settled on a modeling approach laid out in FiveThirtyEight's [methodology for its club soccer predictions](https://fivethirtyeight.com/methodology/how-our-club-soccer-predictions-work/) and further helpfully explained by [Luke Benz's research](https://github.com/lbenz730/soccer_hfa) into shrinking home-field advantage at fan-less soccer matches.

A few inputs go into this model, which I felt were simple enough to be gathered and powerful enough to predict the outcome:

* The time that has elapsed in the tie
* Who the home team was in the tie
* The goal difference between the two teams
* The away goal difference between the two teams
* The difference in the number of players on the field in a game
* The difference in the pre-match betting odds for the first leg of the tie

It took a few steps to arrive at a win probability figure.

First of all, this modeling approach predicts *the number of goals left in the tie* based on the above inputs, following a Poisson regression model implemented in R. Fitting data to a [Poisson distribution](https://en.wikipedia.org/wiki/Poisson_distribution) is called for when the values are discrete (as in integers, not fractions) and typically skewed to the right (mainly bunched up among low values like 0 or 1). That describes soccer goal-scoring tallies almost perfectly.

Secondly, there is not one model but rather hundreds that eventually come together as one. I implemented a version of "localized" regression by calculating different models for each minute of the match. Early in the tie, the models look at 10 minutes of data before and after the minute in focus. Later, the window shrinks to three minutes. In minutes 178, 179 and 180, the prediction is based on just the data in those minutes.

After training the model and generating the predicted goals left for every minute in the tie, I used that metric as the mean (also known as the lambda) of a Poisson distribution. This is the bridge from goals to probabilities. For example, if the model said a particular team had an expectation of 1.5 goals left in the remainder of the tie, this would translate to about a 22% chance of the team scoring 0 goals, a 33% chance of one goal, a 25% chance of two goals, a 13% chance of 3 goals, a 5% chance of four goals, and so on. With those probability distributions for every minute of the tie generated, I arrived at the final win probability metric.

My approach to modeling win probability changed many times as I worked on this. The [model folder](https://github.com/ryanvmenezes/tiepredict/tree/master/model) of my GitHub repo serves as a living document of my successes and many failures with each attempt. It's a messy collection of scripts, but I wanted to preserve a paper trail of all my work. I'm always trying to learn more from the world of statistics, but I've sometimes found actual code hard to come by when trying to get started doing predictive modeling, so I wanted to preserve all the work I had done in the hopes that others may be able to learn from it.

## Are the predictions any good? 

The predictions _seem_ pretty good. By that I mean: when goals happen that _seem_ like they should dramatically shift the balance of the tie, it typically corresponds to a massive change in the win probability. Stronger teams start with high chances of winning and don't become underdogs because of [an early deficit](/tiepredict/ties/2019-cl-1k-3r16-schalke-04-manchester-city/). 

Of course, there are more empirical ways to evaluate this. A simple one is to rephrase the question: If the model predicts something has an X% chance of happening, does it really happen X% of the time? This is referred to as the ["calibration" of the forecast](https://projects.fivethirtyeight.com/checking-our-work/).

Is tiepredict well-calibrated? Here's a look at how it does when it spits out a particular percentage for the team hosting the first leg of the tie:

<table class='table table-sm table-bordered' style='max-width:250px'>
<thead>
  <tr>
    <th colspan="2">Predicted W.P.</th>
    <th></th>
  </tr>
  <tr>
    <th>Low</th>
    <th>High</th>
    <th>Actual W.P.</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>0%</td>
    <td>1%</td>
    <td>0.22%</td>
  </tr>
  <tr>
    <td>1%</td>
    <td>5%</td>
    <td>0.80%</td>
  </tr>
  <tr>
    <td>5%</td>
    <td>10%</td>
    <td>5.51%</td>
  </tr>
  <tr>
    <td>10%</td>
    <td>20%</td>
    <td>14.92%</td>
  </tr>
  <tr>
    <td>20%</td>
    <td>30%</td>
    <td>30.00%</td>
  </tr>
  <tr>
    <td>30%</td>
    <td>40%</td>
    <td>30.61%</td>
  </tr>
  <tr>
    <td>40%</td>
    <td>50%</td>
    <td>50.16%</td>
  </tr>
  <tr>
    <td>50%</td>
    <td>60%</td>
    <td>48.52%</td>
  </tr>
  <tr>
    <td>60%</td>
    <td>70%</td>
    <td>70.23%</td>
  </tr>
  <tr>
    <td>70%</td>
    <td>80%</td>
    <td>70.21%</td>
  </tr>
  <tr>
    <td>80%</td>
    <td>90%</td>
    <td>83.09%</td>
  </tr>
  <tr>
    <td>90%</td>
    <td>95%</td>
    <td>94.57%</td>
  </tr>
  <tr>
    <td>95%</td>
    <td>99%</td>
    <td>98.26%</td>
  </tr>
  <tr>
    <td>99%</td>
    <td>100%</td>
    <td>99.92%</td>
  </tr>
</tbody>
</table>

The results are generally good, but could be better. If tiepredict says a team has a 30% to 40% chance of winning, that team typically wins a little more than 30% of the time. There is some over-confidence at the low end and under-confidence at the high end, which will need to be ironed out in the future.

Was the modeling approach outlined above the best of all my options? That's a tougher question to answer. I compared various metrics for each modeling approach, such as the [log-likelihood](https://raw.githubusercontent.com/ryanvmenezes/tiepredict/master/model/evaluation/compare-log-lik.png) and [root mean squared error](https://raw.githubusercontent.com/ryanvmenezes/tiepredict/master/model/evaluation/compare-rms.png) of predictions for each minute in the tie. The approach I settled on (labelled "v3" in the plots) fared better in some and worse in others. Figuring out why those differences exist will be another focus of improvements.

There are number of other improvements I'd like to make:

* Forecasts toward the end of close games are not very confident, and often drop precipitously as the tie approaches its conclusion. (It is worth noting: A prediction is not made for the last minute of the tie. The probability is simply equal to the 1 if the team hosting the first leg won the tie, or 0 if it was the other team.) A major reason for this, I believe, is that it's unclear to me how much _stoppage time_ was added to the games. Stoppage time additions are left to the discretion of the fourth official and [are notoriously low](https://fivethirtyeight.com/features/world-cup-stoppage-time-is-wildly-inaccurate/). The problem for me is that the amount of stoppage time does not appear to be a part of formal record-keeping (this problem is not specific to FBref). I saw no option other than to cram all stoppage time events into the non-stoppage time minute that they happened: for example, the 45th minute in the first half or the 90th minute at the end of the game. The model sees the 89th minute and to its knowledge thinks there is only one minute left in the tie. However, the actual time remaining is likely far higher. Figuring out a way to add some sort of proxy for stoppage time in each game would be great, but would require much more detailed data that I have found at the moment.
* Forecasts in extra time seem to be all over the place, as well, since extra time is very rare. There is likely a way to incorporate some of the data from the end of the regular part of the tie into the extra time forecasts, but I haven't figured that out yet.
* The forecast ends with extra time, and thus no prediction is made for the handful of ties that go to a [penalty kick shootout](/tiepredict/ties/no-odds/). Furthermore, I've made a simplified assumption that those ties have a 50% chance of each team winning when the shootout starts, which is probably not true. I'd love to develop a system to generate predictions based on historical shootouts across many different competitions (or use [an existing framework](https://fivethirtyeight.com/features/a-chart-for-predicting-penalty-shootout-odds-in-real-time/)), since this is not a phenomenon unique to these ties. However, it has the added quirk of being at one team's home ground, which is usually not the case at World Cups.

## How was this done?

This is truly a "soup to nuts" project that has brought together a lot of varied technical skills I've developed over the years in my professional career. Here are more details on the tools I used, all of which you can see in action in [this project's open-source GitHub repository](https://github.com/ryanvmenezes/tiepredict/):

* I used the R programming language for all the scraping, cleaning and processing of the source data, relying heavily on libraries from what is known as the [tidyverse](https://www.tidyverse.org/). The pipeline I created is long and admittedly messy (so far it has been designed with only me in mind) but it is [documented here](https://github.com/ryanvmenezes/tiepredict/tree/master/data-get). It required some manual work, like reconciling the team name differences between FBref and Odds Portal. I also used built-in R functions to do the Poisson regression modeling.
* When it came time to make a website I turned to [django](https://www.djangoproject.com/), a framework written in python. There are many of these frameworks out there, I just happen to be comfortable with django because of my professional work as a journalist. (Django itself was [created in a newsroom in Kansas](https://en.wikipedia.org/wiki/Django_(web_framework)).) It has always appealed to me because of its ability to make data-driven pages: django easily connects to a database, enabling web developers to rapidly create templatized sites across the full scope of the database. I had ambitious plans to spin up more than a thousand win probability charts and hundreds more pages with information on the teams. With django, that and more was possible.
* The win probability chart itself was created in a javascript library called [d3.js](https://d3js.org/). This is another skill I've used to great effect in my journalism work. d3 is not explicitly a charting library, but provides ways to bind data to the [DOM](https://en.wikipedia.org/wiki/Document_Object_Model) of a webpage, allowing graphical objects to be generated quickly, typically in SVG format. Creating [sports-related data visualizations](https://observablehq.com/@ryanvmenezes/nba-player-hex-calcs) in d3 is another hobby of mine.
* I designed this site using the popular [Bootstrap](https://getbootstrap.com/) HTML and CSS framework. Thanks to Bootstrap, it was easier to make this site fully responsive (as viewable on a phone as on a desktop computer), which was my goal from the outset.
* When it came time to host this site, I opted for a static site hosted on [GitHub pages](https://pages.github.com/), in the same repository as all of the data processing code. I did this for a number of reasons: I wanted to keep everything in one place and dodge issues that arise when hosting a django project with a database backend (not exactly my strong suit), which would have also come at some financial cost. GitHub thankfully hosts fully static sites for free. But I had to get the website that was sitting on a local server on my laptop into static pages. Luckily, the [django-bakery](https://django-bakery.readthedocs.io/en/latest/) library exists to do just that.