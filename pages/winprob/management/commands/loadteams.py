import os
import csv
from tqdm import tqdm
from django.conf import settings
from django.utils.text import slugify
from django.core.management.base import BaseCommand

from winprob.models import *

class Command(BaseCommand):
    def handle(self, *args, **options):
        print('deleting Team model')
        Team.objects.all().delete()
        
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

        teamsshortdatapath = os.path.join(settings.ROOT_DIR, 'data-get', 'assemble', 'teams', 'europe-teams-fbref.csv')
        with open(teamsshortdatapath, 'r') as teamsshortcsvfile:
            teamsshortcsvreader = csv.DictReader(teamsshortcsvfile)
            for row in teamsshortcsvreader:
                team = Team.objects.get(fbrefid=row['clubid'])
                team.shortnames = row['clubshortnames']
                team.save()
                print(f"added short names {row['clubshortnames']} to {team}")
