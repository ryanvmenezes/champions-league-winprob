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

assemble:
	Rscript data-get/assemble/odds/01_create-odds-table.R
	Rscript data-get/assemble/summary/91_finding-missing-ties.R
	Rscript data-get/assemble/summary/00_find-extra-aet-ties.R
	Rscript data-get/assemble/summary/01_compile-tie-summaries.R
	Rscript data-get/assemble/events/01_inflate-events-table.R

runmodelv3predict:
	Rscript model/v3/00_prep-predictors.R
	Rscript model/v3/02_generate-predictions.R
	Rscript model/v3/03_evaluate.R
	Rscript model/v3/04_calculate-tie-metrics.R

runmodelv3:
	Rscript model/v3/00_prep-predictors.R
	Rscript model/v3/01_train.R
	Rscript model/v3/02_generate-predictions.R
	Rscript model/v3/03_evaluate.R
	Rscript model/v3/04_calculate-tie-metrics.R

rs:
	python pages/manage.py runserver

buildserver:
	python pages/manage.py buildserver

makemigrations:
	python pages/manage.py makemigrations

migrate:
	python pages/manage.py migrate

flushdb:
	python pages/manage.py flushdb

loadteams:
	python pages/manage.py loadteams

loadsummary:
	python pages/manage.py loadsummary

loadpredictions:
	python pages/manage.py loadpredictions

loadposts:
	python pages/manage.py loadposts

loadall:
	make loadteams
	make loadsummary
	make loadpredictions

shell:
	python pages/manage.py shell

build:
	python pages/manage.py build
	LC_ALL=C find docs -type f -not -path '*static*' -exec sed -i '' 's|/static/|/tiepredict/static/|g' {} +

everything:
	make updatefbrefgames
	make assemble
	make runmodelv3predict
	make loadall
