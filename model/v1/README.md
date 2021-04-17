# model notes: v1

This was an attempt to use the R package `locfit`, which can be used to set up locally weighted logistic regression (like LOESS but for logistic models). This was inspired by models I had seen in the wild used to forecast win probability for [NBA games](https://www.inpredictable.com/2015/02/updated-nba-win-probability-calculator.html) and [cricket matches](https://saidee27.wordpress.com/2014/09/29/in-game-win-probability-twenty20-cricket/).

However, I could never quite get the locfit models to properly converge to 100% or 0% at the ends of games. I believe this had to do with the ["smoothing window"](https://github.com/ryanvmenezes/futbol-winprob-model/issues/3) argument to the function call, but I could not figure this out on my own. I opted to implement a local logistic regression from scratch in v2, which was much more successful.
