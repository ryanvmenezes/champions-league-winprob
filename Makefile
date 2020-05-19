updatefbrefgames:
	Rscript data-get/fbref/01_scrape-seasons.R
	Rscript data-get/fbref/02_extract-games.R
	Rscript data-get/fbref/03_scrape-games.R

updatefbrefteams:
	Rscript data-get/fbref/00_scrape-teams.R

updatefbrefall:
	make updatefbrefgames
	make updatefbrefteams