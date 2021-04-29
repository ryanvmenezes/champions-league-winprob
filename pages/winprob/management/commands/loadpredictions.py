import os
import csv
from tqdm import tqdm
from django.conf import settings
from django.utils.text import slugify
from django.core.management.base import BaseCommand

from winprob.models import *

class Command(BaseCommand):
    def handle(self, *args, **options):
        print('deleting Prediction model')
        Prediction.objects.all().delete()

        print(f'loading Predction file')
        predictionsdatapath = os.path.join(settings.ROOT_DIR, 'model', 'v3', 'predictions.csv')
        insert_count = Prediction.objects.from_csv(
            predictionsdatapath,
            mapping=dict(
                season='season',
                stagecode='stagecode',
                tieid='tieid',
                t1win='t1win',
                minuteclean='minuteclean',
                minuterown='minuterown',
                is_goal='is.goal',
                is_away_goal='is.away.goal',
                is_red_card='is.red.card',
                goalst1='goals.t1',
                goalst2='goals.t2',
                awaygoalst1='away.goals.t1',
                awaygoalst2='away.goals.t2',
                playerst1='players.t1',
                playerst2='players.t2',
                player='player',
                playerid='playerid',
                eventtype='eventtype',
                eventteam='eventteam',
                actualminute='actualminute',
                predictedprobt1='predictedprobt1',
                likelihood='likelihood',
                error='error',
                sqerror='sqerror',
                chgpredictedprobt1='chgpredictedprobt1',

            )
        )
        print(f"{insert_count} Prediction records inserted")
