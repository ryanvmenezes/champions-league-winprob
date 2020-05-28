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

class Country(BuildableModel):
    country_name = models.CharField(max_length=50)
    slug = models.SlugField(unique=True)

    def __str__(self):
        return self.country_name

    def get_absolute_url(self):
        return reverse('countryteamslist', kwargs={'slug': self.slug})

    def get_slug(self):
        return self.slug


class Team(BuildableModel):
    detail_views = (
        'winprob.views.TeamListView',
        'winprob.views.TeamDetailView',
    )

    team_name = models.CharField(max_length=50)
    slug = models.SlugField(unique=True)
    # country = models.CharField(max_length=50)
    country = models.ForeignKey(Country, on_delete=models.CASCADE)
    fbrefid = models.CharField(max_length=10)

    def __str__(self):
        return self.team_name

    def get_absolute_url(self):
        return reverse('teamdetail', kwargs={'slug': self.slug})

    def get_slug(self):
        return self.slug

