# Create your views here.
from .models import Team
# from django.conf import settings
from django.shortcuts import render
from django.http import HttpResponse
from django.views.generic import ListView, DetailView
from bakery.views import BuildableListView, BuildableDetailView

def index(request):
    return HttpResponse("Hello, world. You're at the winprob index.")

# def team_detail(request, team_slug):
#     try:
#         team = Team.objects.get(team_slug=team_slug)
#     except Team.DoesNotExist:
#         raise Http404("Team does not exist")
#     return render(request, 'winprob/teamdetail.html', {'team': team})

class TeamListView(BuildableListView):
    '''
    A page with all of the teams
    '''
    model = Team
    build_path = 'teams/index.html'
    template_name = 'team_list.html'

    # def get_context_data(self, **kwargs):
    #     # Call the base implementation first to get a context
    #     context = super().get_context_data(**kwargs)
    #     # Add in a QuerySet of all the teams
    #     context['team_list'] = Team.objects.all()
    #     return context

# class TeamView(BuildableDetailView):
#     '''
#     A page for each team
#     '''
#     model = Team
#     def get_url(self, obj):
#         # The URL at which the detail page should appear.
#         return f'{obj.team_slug}'

#     # def get_object(self):
#     #     return get_object_or_404(Team, slug=request.session['user_id'])
#     def get_url(self, obj):
#         # The URL at which the detail page should appear.
#         return '%s' % obj.team_slug
#     def get_build_path(self, obj):
#         dir_path = "team/"
#         dir_path = os.path.join(settings.BUILD_DIR, dir_path, self.get_url(obj))
#         os.path.exists(dir_path) or os.makedirs(dir_path)
#         return os.path.join(dir_path, 'index.html')
#     def get_context_data(self, **kwargs):
#         context = super(TeamView, self).get_context_data(**kwargs)
#         return context