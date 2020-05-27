import os
from .models import Team
from django.conf import settings
from django.shortcuts import render
from django.http import HttpResponse
from django.views.generic import ListView, DetailView
from bakery.views import BuildableListView, BuildableDetailView

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
    # queryset = Team.objects.filter(is_published=True)
    template_name = 'team_detail.html'

    def get_build_path(self, obj):
        dir_path = "teams/"
        dir_path = os.path.join(settings.BUILD_DIR, dir_path, obj.get_slug())
        os.path.exists(dir_path) or os.makedirs(dir_path)
        return os.path.join(dir_path, 'index.html')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        return context