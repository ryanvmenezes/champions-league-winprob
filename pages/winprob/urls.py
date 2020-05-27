from django.urls import path

from . import views

urlpatterns = [
    # path('', views.index, name='index'),
    # path('teams/', views.TeamListView.as_view()),
    # path('team/<team_slug>/', views.team_detail, name='team'),
    # path(
    #     'team/<slug:team_slug>/',
    #     views.TeamView.as_view(),
    #     name="team-page",
    # ),
]

# urlpatterns = patterns('',
#     # url(r'', include(admin.site.urls)),
#     url(
#         r'^team/(?P<slug>[-_\w]+)/$',
#         views.TeamView.as_view(),
#         name="team-page",
#     ),
# )