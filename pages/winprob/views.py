from django.shortcuts import render

# Create your views here.
from django.http import HttpResponse

from .models import *


def index(request):
    return HttpResponse("Hello, world. You're at the winprob index.")

def team_detail(request, team_slug):
    try:
        team = Team.objects.get(team_slug=team_slug)
    except Team.DoesNotExist:
        raise Http404("Team does not exist")
    return render(request, 'winprob/teamdetail.html', {'team': team})