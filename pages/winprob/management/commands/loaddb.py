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
                    aggscore_t1=int(row['aggscore1']) if row['aggscore1'] != '' else None,
                    aggscore_t2=int(row['aggscore2']) if row['aggscore2'] != '' else None,
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
                    print(f'created Tie {tie}')

        print(f'loading Predction file')
        predictionsdatapath = os.path.join(settings.ROOT_DIR, 'model', 'predictions', 'v2.2.1.csv')
        insert_count = Prediction.objects.from_csv(predictionsdatapath)
        print(f"{insert_count} Prediction records inserted")

        excitementdatapath = os.path.join(settings.ROOT_DIR, 'model', 'post-model', 'excitement.csv')
        with open(excitementdatapath, 'r') as excitementcsvfile:
            excitementcsvreader = csv.DictReader(excitementcsvfile)
            for row in excitementcsvreader:
                tie = Tie.objects.get(
                    season=int(row['season']),
                    stage=row['stagecode'],
                    tieid=row['tieid'],
                )
                tie.excitement = float(row['excitement'])
                tie.save()
                print(f'saved excitement for {tie}')

        minprobdatapath = os.path.join(settings.ROOT_DIR, 'model', 'post-model', 'min-prob-winner.csv')
        with open(minprobdatapath, 'r') as minprobcsvfile:
            minprobcsvreader = csv.DictReader(minprobcsvfile)
            for row in minprobcsvreader:
                tie = Tie.objects.get(
                    season=int(row['season']),
                    stage=row['stagecode'],
                    tieid=row['tieid'],
                )
                tie.minprob_winner = float(row['minprob'])
                tie.save()
                print(f'saved min prob winner for {tie}')

        tensiondatapath = os.path.join(settings.ROOT_DIR, 'model', 'post-model', 'tension.csv')
        with open(tensiondatapath, 'r') as tensioncsvfile:
            tensioncsvreader = csv.DictReader(tensioncsvfile)
            for row in tensioncsvreader:
                tie = Tie.objects.get(
                    season=int(row['season']),
                    stage=row['stagecode'],
                    tieid=row['tieid'],
                )
                tie.tension = float(row['tension'])
                tie.save()
                print(f'saved tension for {tie}')

        teamsshortdatapath = os.path.join(settings.ROOT_DIR, 'data-get', 'assemble', 'teams', 'europe-teams-fbref.csv')
        with open(teamsshortdatapath, 'r') as teamsshortcsvfile:
            teamsshortcsvreader = csv.DictReader(teamsshortcsvfile)
            for row in teamsshortcsvreader:
                team = Team.objects.get(fbrefid=row['clubid'])
                team.shortnames = row['clubshortnames']
                team.save()
                print(f"added short names {row['clubshortnames']} to {team}")
