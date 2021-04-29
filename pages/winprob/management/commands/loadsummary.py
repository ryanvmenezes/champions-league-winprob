import os
import csv
from tqdm import tqdm
from django.conf import settings
from django.utils.text import slugify
from django.core.management.base import BaseCommand

from winprob.models import *

class Command(BaseCommand):
    def handle(self, *args, **options):
        print('deleting Tie model')
        Tie.objects.all().delete()
        print('deleting Season model')
        Season.objects.all().delete()

        summarydatapath = os.path.join(settings.ROOT_DIR, 'model', 'v3', 'tie-wp-summary.csv')
        with open(summarydatapath, 'r') as summarycsvfile:
            summarycsvreader = csv.DictReader(summarycsvfile)
            for row in summarycsvreader:
                season, season_created = Season.objects.get_or_create(
                    year=int(row['season']),
                    competition=row['stagecode'][:2],
                    slug=f"{row['season']}-{row['stagecode'][:2]}"
                )
                if season_created:
                    print(f'created season {season}')

                tie, tie_created = Tie.objects.get_or_create(
                    slug=f"{slugify(row['season'])}-{slugify(row['stagecode'])}-{slugify(row['team1'])}-{slugify(row['team2'])}",
                    season=int(row['season']),
                    season_obj=season,
                    stagecode=row['stagecode'],
                    tieid=row['tieid'],
                    competition_code=row['stagecode'][:2],
                    competition=row['competition'],
                    stage=row['round'],
                    dates=row['dates'],
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
                    in_progress_halfway=(row['in_progress_halfway'] == 'TRUE'),
                    excitement=float(row['excitement']) if row['excitement'] != '' else None,
                    comeback=float(row['comeback']) if row['comeback'] != '' else None,
                    tension=float(row['tension']) if row['tension'] != '' else None,
                )
                if tie_created:
                    print(f'created Tie {tie}')
