updatefbrefgames:
	Rscript data-get/fbref/01_scrape-seasons.R
	Rscript data-get/fbref/02_extract-games.R
	Rscript data-get/fbref/03_scrape-games.R

updatefbrefteams:
	Rscript data-get/fbref/00_scrape-teams.R

updatefbrefall:
	make updatefbrefgames
	make updatefbrefteams

updateodds:
	-docker stop $(docker ps -a -q)
	-docker rm $(docker ps -a -q)
	-docker run -d -p 4445:4444 selenium/standalone-firefox:3.141.59
	Rscript data-get/oddsportal/01_scrape-odds.R
	Rscript data-get/oddsportal/02_parse-odds.R

runmodelv1:
	Rscript model/v1/01_model-predict.R
	Rscript model/v1/02_plot.R
	
createmodels:
	Rscript model/v1/01_model-predict.R
	Rscript model/v2.1/01_model-predict.R
	Rscript model/v2.2/01_model-predict.R
	Rscript model/v2.2.1/01_model-predict.R