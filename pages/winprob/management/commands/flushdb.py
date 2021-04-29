import os
import csv
from django.core.management.base import BaseCommand

from winprob.models import *

class Command(BaseCommand):
    def handle(self, *args, **options):
        print('deleting Team model')
        Team.objects.all().delete()
        print('deleting Country model')
        Country.objects.all().delete()
        print('deleting Tie model')
        Tie.objects.all().delete()
        print('deleting Season model')
        Season.objects.all().delete()
        print('deleting Prediction model')
        Prediction.objects.all().delete()
