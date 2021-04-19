import os
import json
from .models import *
from django.conf import settings
from django.db.models import Q, Count
from django.http import HttpResponse, JsonResponse
from django.shortcuts import render, get_object_or_404
from django.views.generic import ListView, DetailView, RedirectView
from bakery.views import BuildableListView, BuildableDetailView, BuildableRedirectView

class ToTeamsRedirectView(BuildableRedirectView):
    pattern_name = 'teamlist'
    build_path = 'index.html'
    # permanent = True

class CountryListView(BuildableListView):
    '''
    A page with all of the teams listed by country
    '''
    build_path = 'teams/index.html'
    template_name = 'country_list.html'
    context_object_name = 'country_list'
    queryset = Country.objects.all()\
        .annotate(num_teams = Count('team'))\
        .order_by('-num_teams')

class TieListView(BuildableListView):
    '''
    A page with a list of the 100 best ties (rated by comeback)
    '''
    # model = Tie
    build_path = 'ties/index.html'
    template_name = 'ties_list.html'
    context_object_name = 'ties'

    def get_queryset(self):
        ties = Tie.objects.all()
        return sorted(ties, key=lambda x: (x.comeback is None, x.comeback))[:100]

class TieDetailView(BuildableDetailView):
    '''
    A page for each Tie
    '''
    model = Tie
    template_name = 'tie_detail.html'
    context_object_name = 'tie'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        preds = context['tie'].get_predictions()\
            .values('minuteclean','minuterown','predictedprobt1')\
            .order_by('minuteclean', 'minuterown')
        context['preds'] = json.dumps(list(preds), ensure_ascii=False)
        events = context['tie'].get_predictions()\
            .filter(~Q(eventtype = None))\
            .values('minuteclean', 'minuterown', 'player', 'playerid', 'eventtype', 'is_goal', 'is_away_goal', 'is_red_card', 'predictedprobt1', 'chgpredictedprobt1')\
            .order_by('minuteclean', 'minuterown')
        context['events'] = json.dumps(list(events), ensure_ascii=False)
        return context

    def get_build_path(self, obj):
        dir_path = "ties/"
        dir_path = os.path.join(settings.BUILD_DIR, dir_path, obj.get_slug())
        os.path.exists(dir_path) or os.makedirs(dir_path)
        return os.path.join(dir_path, 'index.html')

class TeamDetailView(BuildableDetailView):
    '''
    A page for each team
    '''
    model = Team
    template_name = 'team_detail.html'
    context_object_name = 'team'

    def get_build_path(self, obj):
        dir_path = "teams/"
        dir_path = os.path.join(settings.BUILD_DIR, dir_path, obj.get_slug())
        os.path.exists(dir_path) or os.makedirs(dir_path)
        return os.path.join(dir_path, 'index.html')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        team = context['team']
        context['ties'] = Tie.objects.filter(Q(team1 = team) | Q(team2 = team))\
            .order_by('-season', 'stage')
        return context

class AwayGoalsRuleListView(BuildableListView):
    '''
    A page with all of the ties decided by the away goals rule
    '''
    build_path = 'ties/away-goals-rule/index.html'
    template_name = 'agr_list.html'
    context_object_name = 'ties'
    queryset = Tie.objects.filter(away_goals_rule=True)\
        .order_by('-season', 'stage')

class AfterExtraTimeListView(BuildableListView):
    '''
    A page with all of the ties that went to extra time after 180 minutes
    '''
    build_path = 'ties/after-extra-time/index.html'
    template_name = 'aet_list.html'
    context_object_name = 'ties'
    queryset = Tie.objects.filter(after_extra_time=True)\
        .order_by('-season', 'stage')

class PenaltyKicksListView(BuildableListView):
    '''
    A page with all of the ties that required a penalty kick shootout
    '''
    build_path = 'ties/penalty-kicks/index.html'
    template_name = 'pk_list.html'
    context_object_name = 'ties'
    queryset = Tie.objects.filter(penalty_kicks=True)\
        .order_by('-season', 'stage')

class SeasonListView(BuildableListView):
    build_path = 'seasons/index.html'
    template_name = 'season_list.html'
    context_object_name = 'seasons'

    queryset = Tie.objects.all()\
        .values('season')\
        .annotate(total = Count('season'))\
        .order_by('-season')

# class CountryTeamsDetailView(BuildableDetailView):
#     '''
#     A page for each country, with all of its teams
#     '''
#     model = Country
#     template_name = 'country_teams_list.html'
#     context_object_name = 'country'
#
#     def get_build_path(self, obj):
#         dir_path = "countries/"
#         dir_path = os.path.join(settings.BUILD_DIR, dir_path, obj.get_slug())
#         os.path.exists(dir_path) or os.makedirs(dir_path)
#         return os.path.join(dir_path, 'index.html')
#
#     def get_context_data(self, **kwargs):
#         context = super().get_context_data(**kwargs)
#         context['country_teams_list'] = Team.objects.filter(country=context['country'])
#         return context


# class TeamListView(BuildableListView):
#     '''
#     A page with all of the teams
#     '''
#     model = Team
#     build_path = 'teams/index.html'
#     template_name = 'team_list.html'
