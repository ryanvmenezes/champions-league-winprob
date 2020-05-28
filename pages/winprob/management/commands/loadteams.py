import os
import csv
from django.conf import settings
from django.utils.text import slugify
from django.core.management.base import BaseCommand

from winprob.models import *

class Command(BaseCommand):
    def handle(self, *args, **options):
        datapath = os.path.join(settings.ROOT_DIR, 'data-get', 'assemble', 'teams', 'teams.csv')
        with open(datapath, 'r') as csvfile:
            csvreader = csv.DictReader(csvfile)
            for row in csvreader:
                country, ccreated = Country.objects.get_or_create(
                    country_name = row['teamcountry'],
                    slug = slugify(row['teamcountry'])
                )
                print(f'{"created" if ccreated else "retrieved"} country {country.country_name}')
                team, tcreated = Team.objects.get_or_create(
                    team_name = row['teamname'],
                    fbrefid = row['fbrefid'],
                    country = country,
                    slug = slugify(row['teamname'])
                )
                print(f'{"created" if tcreated else "retrieved"} team {team.team_name}')
