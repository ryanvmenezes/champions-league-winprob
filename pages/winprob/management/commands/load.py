import os
import csv
from tqdm import tqdm
from django.conf import settings
from django.utils.text import slugify
from django.core.management.base import BaseCommand

from winprob.models import *

class Command(BaseCommand):
    def handle(self, *args, **options):
        teamsdatapath = os.path.join(settings.ROOT_DIR, 'data-get', 'assemble', 'teams', 'teams.csv')
        with open(teamsdatapath, 'r') as teamscsvfile:
            teamscsvreader = csv.DictReader(teamscsvfile)
            for row in teamscsvreader:
                country, country_created = Country.objects.get_or_create(
                    name=row['teamcountry'],
                    slug=slugify(row['teamcountry'])
                )
                if country_created:
                    print(f'created Country {country.name}')
                team, team_created = Team.objects.get_or_create(
                    name=row['teamname'],
                    fbrefid=row['fbrefid'],
                    country=country,
                    slug=slugify(row['teamname'])
                )
                if team_created:
                    print(f'created Team {team.name}')

        summarydatapath = os.path.join(settings.ROOT_DIR, 'data-get', 'assemble', 'summary', 'summary.csv')
        with open(summarydatapath, 'r') as summarycsvfile:
            summarycsvreader = csv.DictReader(summarycsvfile)
            for row in summarycsvreader:
                tie, tie_created = Tie.objects.get_or_create(
                    slug=f"{slugify(row['season'])}-{slugify(row['stagecode'])}-{slugify(row['team1'])}-{slugify(row['team2'])}",
                    season=int(row['season']),
                    competition=row['stagecode'][:2],
                    stage=row['stagecode'],
                    tieid=row['tieid'],
                    team1=Team.objects.get(fbrefid=row['teamid1']) if row['teamid1'] != '' else None,
                    team2=Team.objects.get(fbrefid=row['teamid2']) if row['teamid2'] != '' else None,
                    winning_team=Team.objects.get(fbrefid=row['winnerid']) if row['winnerid'] != '' else None,
                    result=row['result'],
                    aggscore=row['aggscore'],
                    score_leg1=row['score1'],
                    score_leg2=row['score2'],
                    away_goals_rule=(row['agr'] == 'TRUE'),
                    after_extra_time=(row['aet'] == 'TRUE'),
                    penalty_kicks=(row['pk'] == 'TRUE'),
                    has_events=(row['has_events'] == 'TRUE'),
                    has_odds=(row['has_odds'] == 'TRUE'),
                    has_invalid_match=(row['has_invalid_match'] == 'TRUE'),
                    in_progress=(row['in_progress'] == 'TRUE'),
                )
                if tie_created:
                    print(f'created Tie {tie.season} {tie}')

        print(f'loading Predction file')
        predictionsdatapath = os.path.join(settings.ROOT_DIR, 'model', 'predictions', 'v2.2.1.csv')
        insert_count = Prediction.objects.from_csv(predictionsdatapath)
        print(f"{insert_count} Prediction records inserted")
        
        
