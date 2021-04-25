import os
import json
from .models import *
from django.conf import settings
from django.db.models import Q, Count, Func, F
from django.http import HttpResponse, JsonResponse
from django.shortcuts import render, get_object_or_404
from django.views.generic import ListView, DetailView, RedirectView
from bakery.views import BuildableTemplateView, BuildableListView, BuildableDetailView, BuildableRedirectView

class ToTeamsRedirectView(BuildableRedirectView):
    pattern_name = 'teamlist'
    build_path = 'index.html'
    permanent = False

class CountryListView(BuildableListView):
    '''
    A page with all of the teams listed by country
    '''
    build_path = 'teams/index.html'
    template_name = 'country_list.html'
    context_object_name = 'country_list'
    queryset = Country.objects.all()\
        .annotate(num_teams = Count('team'))\
        .order_by('-num_teams', 'name')

class ToComebackRedirectView(BuildableRedirectView):
    pattern_name = 'comebacklist'
    build_path = 'ties/index.html'
    permanent = False

class ComebackListView(BuildableListView):
    '''
    A page with a list of the top 100 ties sorted by biggest comeback
    '''
    # model = Tie
    build_path = 'ties/comeback/index.html'
    template_name = 'comeback_list.html'
    context_object_name = 'ties'

    def get_queryset(self):
        ties = Tie.objects.filter(~Q(comeback=None))
        return sorted(ties, key=lambda x: x.comeback)[:100]

class ExcitementListView(BuildableListView):
    '''
    A page with a list of the top 100 ties sorted by excitement
    '''
    # model = Tie
    build_path = 'ties/excitement/index.html'
    template_name = 'excitement_list.html'
    context_object_name = 'ties'

    def get_queryset(self):
        ties = Tie.objects.filter(~Q(excitement=None))
        return sorted(ties, key=lambda x: x.excitement, reverse = True)[:100]

class TensionListView(BuildableListView):
    '''
    A page with a list of the top 100 ties sorted by tension
    '''
    # model = Tie
    build_path = 'ties/tension/index.html'
    template_name = 'tension_list.html'
    context_object_name = 'ties'

    def get_queryset(self):
        ties = Tie.objects.filter(~Q(tension=None))
        return sorted(ties, key=lambda x: x.tension)[:100]

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
            .filter(~Q(eventtype=None))\
            .values(
                'minuteclean', 'minuterown',
                'eventteam', 'player', 'playerid', 'eventtype', 'actualminute',
                'is_goal', 'is_away_goal', 'is_red_card',
                'goalst1', 'goalst2', 'awaygoalst1', 'awaygoalst2',
                'predictedprobt1', 'chgpredictedprobt1'
            )\
            .order_by('minuteclean', 'minuterown')
        events = [dict(e, minute_type='a_event') for e in events]

        context['aet'] = context['tie'].after_extra_time

        def filter_by_minute(minute):
            return context['tie'].get_predictions()\
                .filter(Q(minuteclean=minute))\
                .values(
                    'minuteclean', 'minuterown',
                    'eventteam', 'player', 'playerid', 'eventtype', 'actualminute',
                    'is_goal', 'is_away_goal', 'is_red_card',
                    'goalst1', 'goalst2', 'awaygoalst1', 'awaygoalst2',
                    'predictedprobt1', 'chgpredictedprobt1',
                )\
                .order_by('minuteclean', '-minuterown')
        minute_0 = [dict(e, minute_type='b_match_state') for e in filter_by_minute(0)[:1]]
        minute_90 = [dict(e, minute_type='b_match_state') for e in filter_by_minute(90)[:1]]
        minute_180 = [dict(e, minute_type='b_match_state') for e in filter_by_minute(180)[:1]]
        events.extend(minute_0)
        events.extend(minute_90)
        events.extend(minute_180)
        if context['aet']:
            minute_210 = [dict(e, minute_type='b_match_state') for e in filter_by_minute(210)]
            events.extend(minute_210)

        events = sorted(events, key=lambda i: (i['minuteclean'], i['minuterown'], i['minute_type']))

        context['events'] = events
        context['events_json'] = json.dumps(list(events), ensure_ascii=False)

        context['num_ties'] = len(Tie.objects.filter(~Q(comeback=None) & ~Q(excitement=None) & ~Q(tension=None)))
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
            .order_by('-season', '-competition_code', '-stagecode')
        return context

class AwayGoalsRuleListView(BuildableListView):
    '''
    A page with all of the ties decided by the away goals rule
    '''
    build_path = 'ties/away-goals-rule/index.html'
    template_name = 'agr_list.html'
    context_object_name = 'ties'
    queryset = Tie.objects.filter(away_goals_rule=True)\
        .order_by('-season', '-competition_code', '-stagecode')

class AfterExtraTimeListView(BuildableListView):
    '''
    A page with all of the ties that went to extra time after 180 minutes
    '''
    build_path = 'ties/after-extra-time/index.html'
    template_name = 'aet_list.html'
    context_object_name = 'ties'
    queryset = Tie.objects.filter(after_extra_time=True)\
        .order_by('-season', '-competition_code', '-stagecode')

class PenaltyKicksListView(BuildableListView):
    '''
    A page with all of the ties that required a penalty kick shootout
    '''
    build_path = 'ties/penalty-kicks/index.html'
    template_name = 'pk_list.html'
    context_object_name = 'ties'
    queryset = Tie.objects.filter(penalty_kicks=True)\
        .order_by('-season', '-competition_code', '-stagecode')

class SeasonListView(BuildableListView):
    build_path = 'seasons/index.html'
    template_name = 'season_list.html'
    context_object_name = 'seasons'

    queryset = Tie.objects.all()\
        .values('season')\
        .annotate(total = Count('season'))\
        .order_by('-season')

class GoalsListView(BuildableTemplateView):
    build_path = 'goals/index.html'
    template_name = 'goals_list.html'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        goals = Prediction.objects.filter(is_goal=True)\
            .annotate(abschg = Func(F('chgpredictedprobt1'), function='ABS'))\
            .order_by('-abschg')[:100]
        clean_goals = []
        for g in goals:
            tie = Tie.objects.get(
                season=g.season,
                stagecode=g.stagecode,
                tieid=g.tieid
            )
            clean_goals.append(
                dict(
                    tie=tie,
                    is_away_goal=g.is_away_goal,
                    player=g.player,
                    goalst1=g.goalst1,
                    goalst2=g.goalst2,
                    awaygoalst1=g.awaygoalst1,
                    awaygoalst2=g.awaygoalst2,
                    eventteam=g.eventteam,
                    minuteclean=g.minuteclean,
                    actualminute=g.actualminute,
                    abschg=g.abschg,
                    season=g.season,
                    competition=tie.get_short_competition()
                )
            )
        context['goals'] = clean_goals
        return context

class PostView(BuildableDetailView):
    model = Post
    template_name = 'post.html'
    context_object_name = 'post'

    def get_build_path(self, obj):
        dir_path = "posts/"
        dir_path = os.path.join(settings.BUILD_DIR, dir_path, obj.get_slug())
        os.path.exists(dir_path) or os.makedirs(dir_path)
        return os.patn(dir_path, 'index.html')


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
