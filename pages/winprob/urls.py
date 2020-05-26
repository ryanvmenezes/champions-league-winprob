from django.urls import path

from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('team/<team_slug>/', views.team_detail, name='team'),
]