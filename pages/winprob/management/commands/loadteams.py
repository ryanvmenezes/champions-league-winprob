import os
import csv
from django.conf import settings
from django.utils.text import slugify
from django.core.management.base import BaseCommand

from winprob.models import Team

class Command(BaseCommand):
    def handle(self, *args, **options):
        Team.objects.all().delete()
        datapath = os.path.join(settings.ROOT_DIR, 'data-get', 'assemble', 'teams', 'teams.csv')
        with open(datapath, 'r') as csvfile:
            csvreader = csv.DictReader(csvfile)
            for row in csvreader:
                # print(row)
                obj, created = Team.objects.get_or_create(
                    team_name = row['teamname'],
                    fbrefid = row['fbrefid'],
                    country = row['teamcountry'],
                    team_slug = slugify(row['teamname'])
                )
                print(f'{"created" if created else "retrieved"} team {obj.team_name}')
