import os
import csv
from django.core.management.base import BaseCommand

from winprob.models import Team, Country

class Command(BaseCommand):
    def handle(self, *args, **options):
        print('deleting Team model')
        Team.objects.all().delete()
        print('deleting Country model')
        Country.objects.all().delete()