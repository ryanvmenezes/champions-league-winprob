"""pages URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/3.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from winprob import views
from django.contrib import admin
from django.urls import include, path

site_path = 'futbol-winprob-model/'

urlpatterns = [
    path(
        site_path,
        include([
            path('admin/', admin.site.urls),
            path('', views.ToTeamsRedirectView.as_view(), name='homepage'),
            path('teams/', views.CountryListView.as_view(), name='teamlist'),
            path('teams/<slug:slug>/', views.TeamDetailView.as_view(), name='teamdetail'),
            path('ties/', views.TieListView.as_view(), name='tieslist'),
            path('ties/away-goals-rule/', views.AwayGoalsRuleListView.as_view(), name='agrlist'),
            path('ties/after-extra-time/', views.AfterExtraTimeListView.as_view(), name='aetlist'),
            path('ties/penalty-kicks/', views.PenaltyKicksListView.as_view(), name='pklist'),
            path('ties/<slug:slug>/', views.TieDetailView.as_view(), name='tiedetail'),
            path('seasons/', views.SeasonListView.as_view(), name='seasonlist'),
            # path('countries/', views.CountryListView.as_view(), name='countrylist'),
            # path('countries/<slug:slug>/', views.CountryTeamsDetailView.as_view(), name='countryteamslist'),
        ])
    )
]
