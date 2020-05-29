import os
from .models import *
from django.conf import settings
from django.db.models import Count
from django.http import HttpResponse
from django.shortcuts import render, get_object_or_404
from django.views.generic import ListView, DetailView, RedirectView
from bakery.views import BuildableListView, BuildableDetailView, BuildableRedirectView

class ToTeamsRedirectView(BuildableRedirectView):
    # url = 'teams/'
    pattern_name = 'teamlist'
    build_path = 'index.html'
    permanent = True

class TeamListView(BuildableListView):
    '''
    A page with all of the teams
    '''
    model = Team
    build_path = 'teams/index.html'
    template_name = 'team_list.html'

class TeamDetailView(BuildableDetailView):
    '''
    A page for each team
    '''
    model = Team
    template_name = 'team_detail.html'

    def get_build_path(self, obj):
        dir_path = "teams/"
        dir_path = os.path.join(settings.BUILD_DIR, dir_path, obj.get_slug())
        os.path.exists(dir_path) or os.makedirs(dir_path)
        return os.path.join(dir_path, 'index.html')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        return context

class CountryListView(BuildableListView):
    '''
    A page with all of the countries
    '''
    build_path = 'countries/index.html'
    template_name = 'country_list.html'
    context_object_name = 'country_list'
    queryset = Country.objects.all()\
        .annotate(num_teams = Count('team'))\
        .order_by('-num_teams')

class CountryTeamsListView(BuildableDetailView):
    '''
    A page with all of the teams for a country
    '''
    model = Country
    template_name = 'country_teams_list.html'
    context_object_name = 'country'

    def get_build_path(self, obj):
        dir_path = "countries/"
        dir_path = os.path.join(settings.BUILD_DIR, dir_path, obj.get_slug())
        os.path.exists(dir_path) or os.makedirs(dir_path)
        return os.path.join(dir_path, 'index.html')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['country_teams_list'] = Team.objects.filter(country=context['country'])
        return context
