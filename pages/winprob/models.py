from django.db import models
from django.urls import reverse
from bakery.models import BuildableModel

class Country(BuildableModel):
    detail_views = (
        'winprob.views.CountryListView',
        'winprob.views.CountryTeamsDetailView',
    )
    name = models.CharField(max_length=50)
    slug = models.SlugField(unique=True)

    def __str__(self):
        return self.name

    def get_absolute_url(self):
        return reverse('countryteamslist', kwargs={'slug': self.slug})

    def get_slug(self):
        return self.slug


class Team(BuildableModel):
    detail_views = (
        'winprob.views.TeamListView',
        'winprob.views.TeamDetailView',
    )

    name = models.CharField(max_length=50)
    slug = models.SlugField(unique=True)
    country = models.ForeignKey(Country, on_delete=models.CASCADE)
    fbrefid = models.CharField(max_length=10)

    def __str__(self):
        return self.name

    def get_absolute_url(self):
        return reverse('teamdetail', kwargs={'slug': self.slug})

    def get_slug(self):
        return self.slug

class Tie(BuildableModel):
    season = models.IntegerField()
    COMPETITION_CHOICES = [
        ('cl', 'UEFA Champions League'),
        ('el', 'UEFA Europa League'),
    ]
    competition = models.CharField(
        max_length=5,
        choices=COMPETITION_CHOICES
    )
    STAGE_CHOICES = [
        ('cl-0q-1fqr', 'Champions League First Qualifying Round'),
        ('cl-0q-2sqr', 'Champions League Second Qualifying Round'),
        ('cl-0q-3tqr', 'Champions League Third Qualifying Round'),
        ('cl-0q-4po', 'Champions League Qualifying Play-off Round'),
        ('cl-1k-1r16', 'Champions League Round of 16'),
        ('cl-1k-2qf', 'Champions League Quarterfinals'),
        ('cl-1k-3sf', 'Champions League Semifinals'),
        ('el-0q-0pre', 'Europa League Preliminary Qualifying Round'),
        ('el-0q-1fqr', 'Europa League First Qualifying Round'),
        ('el-0q-2sqr', 'Europa League First Qualifying Round'),
        ('el-0q-3tqr', 'Europa League First Qualifying Round'),
        ('el-0q-4po', 'Europa League Qualifying Play-off Round'),
        ('el-1k-1r32', 'Europa League Round of 32'),
        ('el-1k-2r16', 'Europa League Round of 16'),
        ('el-1k-3qf', 'Europa League Quarterfinals'),
        ('el-1k-4sf', 'Europa League Semifinals'),
    ]
    stage = models.CharField(
        max_length=15,
        choices=STAGE_CHOICES
    )
    tieid = models.CharField(max_length=20)
    team1 = models.ForeignKey(Team, on_delete=models.CASCADE, related_name='team1', null=True)
    team2 = models.ForeignKey(Team, on_delete=models.CASCADE, related_name='team2', null=True)
    winning_team = models.ForeignKey(Team, on_delete=models.CASCADE, related_name='winning_team', null=True)
    result = models.CharField(max_length=100)
    aggscore = models.CharField(max_length=10)
    score_leg1 = models.CharField(max_length=10)
    score_leg2 = models.CharField(max_length=10)
    away_goals_rule = models.BooleanField()
    after_extra_time = models.BooleanField()
    penalty_kicks = models.BooleanField()
    has_events = models.BooleanField()
    has_odds = models.BooleanField()
    has_invalid_match = models.BooleanField()
    in_progress = models.BooleanField()
