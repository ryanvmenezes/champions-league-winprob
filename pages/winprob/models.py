from django.db import models
from django.urls import reverse
from bakery.models import BuildableModel

class Competition(BuildableModel):
    COMPETITION_CHOICES = [
        ('cl', 'UEFA Champions League'),
        ('el', 'UEFA Europa League'),
    ]
    competition_name = models.CharField(
        max_length=5,
        choices=COMPETITION_CHOICES
    )

class Team(BuildableModel):
    detail_views = (
        'winprob.views.TeamListView',
        'winprob.views.TeamDetailView',
    )

    team_name = models.CharField(max_length=50)
    slug = models.CharField(max_length=50)
    country = models.CharField(max_length=50)
    fbrefid = models.CharField(max_length=10)
    # other_names = models.CharField(max_length=100)

    def get_absolute_url(self):
        return reverse('teamdetail', kwargs={'slug': self.slug})

    def get_slug(self):
        return self.slug

