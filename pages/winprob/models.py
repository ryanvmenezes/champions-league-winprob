from django.db import models
from django.db.models import Q
from django.urls import reverse
from postgres_copy import CopyManager
from bakery.models import BuildableModel

import unicodedata

class Post(BuildableModel):
    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    body = models.TextField()

    def __str__(self):
        return self.title

    def get_slug(self):
        return self.slug

    def get_absolute_url(self):
        return reverse('postdetail', kwargs={'slug': self.slug})

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
    shortnames = models.TextField(null=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name

    def num_ties(self):
        return len(self.team1.all()) + len(self.team2.all())

    def get_absolute_url(self):
        return reverse('teamdetail', kwargs={'slug': self.slug})

    def get_slug(self):
        return self.slug

    def short_name(self):
        shortnames = self.shortnames.split('|')
        return sorted(shortnames, key=lambda x: len(x))[0]

    def remove_accents(self, input_str):
        nfkd_form = unicodedata.normalize('NFKD', input_str)
        only_ascii = nfkd_form.encode('ASCII', 'ignore')
        return only_ascii

    def code_name(self):
        return self.remove_accents(self.short_name()).decode('ascii').replace(' ', '').upper()[:3]

class Season(BuildableModel):
    year = models.IntegerField()
    competition = models.CharField(max_length=10)
    slug = models.SlugField(unique=True, max_length=200)

    def __str__(self):
        return f'{self.year} {self.competition}'

    def get_full_competition(self):
        if self.competition == 'el':
            return 'Europa League'
        if self.competition == 'cl':
            return 'Champions League'

    def get_full_season(self):
        return f'{self.year-1}-{self.year}'

    def get_ties(self):
        return Tie.objects.filter(season_obj=self)

    def get_num_ties(self):
        return len(self.get_ties())

    def get_absolute_url(self):
        return reverse('seasondetail', kwargs={'slug': self.slug})

    def get_slug(self):
        return self.slug


class Tie(BuildableModel):
    slug = models.SlugField(unique=True, max_length=200)
    season = models.IntegerField()
    season_obj = models.ForeignKey(Season, on_delete=models.CASCADE, related_name='season', null=True)
    stagecode = models.CharField(max_length=50)
    tieid = models.CharField(max_length=20)
    competition_code = models.CharField(max_length=10)
    competition = models.CharField(max_length=100)
    stage = models.CharField(max_length=200)
    dates = models.CharField(max_length=200)
    team1 = models.ForeignKey(Team, on_delete=models.CASCADE, related_name='team1', null=True)
    team2 = models.ForeignKey(Team, on_delete=models.CASCADE, related_name='team2', null=True)
    winning_team = models.ForeignKey(Team, on_delete=models.CASCADE, related_name='winning_team', null=True)
    result = models.CharField(max_length=200)
    aggscore = models.CharField(max_length=10)
    aggscore_t1 = models.IntegerField(null=True)
    aggscore_t2 = models.IntegerField(null=True)
    score_leg1 = models.CharField(max_length=10)
    score_leg2 = models.CharField(max_length=10)
    away_goals_rule = models.BooleanField()
    after_extra_time = models.BooleanField()
    penalty_kicks = models.BooleanField()
    has_events = models.BooleanField()
    has_odds = models.BooleanField()
    has_invalid_match = models.BooleanField()
    in_progress = models.BooleanField()
    in_progress_halfway = models.BooleanField()
    excitement = models.FloatField(null=True)
    comeback = models.FloatField(null=True)
    tension = models.FloatField(null=True)

    def __str__(self):
        return f"{self.season} {self.team1 if self.team1 is not None else 'UNKNOWN'} v. {self.team2 if self.team2 is not None else 'UNKNOWN'}"

    def get_predictions(self):
        return Prediction.objects.filter(
            season=self.season,
            stagecode=self.stagecode,
            tieid=self.tieid
        )

    def get_short_stage(self):
        return self.stage\
            .replace('Round', 'Rd.')\
            .replace('Qualifying', 'Qual.')\
            .replace('round', 'Rd.')\
            .replace('qualifying', 'Qual.')

    def get_short_competition(self):
        xwalk = {
            'UEFA Champions League': 'C.L.',
            'UEFA Europa League': 'E.L.',
        }
        return xwalk.get(self.competition)

    def is_knockout(self):
        return '1k' in self.stagecode

    def get_absolute_url(self):
        return reverse('tiedetail', kwargs={'slug': self.slug})

    def get_tie_name(self):
        return str(self)

    def get_slug(self):
        return self.slug

    def t1win(self):
        if self.team1 is None or self.team2 is None or self.winning_team is None:
            return None
        return self.team1.fbrefid == self.winning_team.fbrefid

    def get_comeback_rank(self):
        return [
            t['tieid'] for t in
            Tie.objects.filter(~Q(comeback=None) & ~Q(excitement=None) & ~Q(tension=None))\
                .order_by('comeback')\
                .values('tieid')
        ].index(self.tieid) + 1

    def get_excitement_rank(self):
        return [
            t['tieid'] for t in
            Tie.objects.filter(~Q(comeback=None) & ~Q(excitement=None) & ~Q(tension=None))\
                .order_by('-excitement')\
                .values('tieid')
        ].index(self.tieid) + 1

    def get_tension_rank(self):
        return [
            t['tieid'] for t in
            Tie.objects.filter(~Q(comeback=None) & ~Q(excitement=None) & ~Q(tension=None))\
                .order_by('tension')\
                .values('tieid')
        ].index(self.tieid) + 1

    # def get_next_knockout_match(self):
    #     round_orders = {
    #         'cl-0q': ['cl-0q-1fqr','cl-0q-2sqr','cl-0q-3tqr','cl-0q-4po'],
    #         'cl-1k': ['cl-1k-1r16','cl-1k-2qf','cl-1k-3sf'],
    #         'el-0q': ['el-0q-0pre','el-0q-1fqr','el-0q-2sqr','el-0q-3tqr','el-0q-4po'],
    #         'el-1k': ['el-1k-1r32','el-1k-2r16','el-1k-3qf','el-1k-4sf'],
    #     }
    #     round_order = round_orders[self.stage[:5]]
    #     match_index = round_order.index(self.stage)
    #     if match_index == len(round_order) - 1:
    #         return None
    #     winning_team = self.team1 if self.t1win() else self.team2
    #     return Tie.objects.get(
    #         Q(season = self.season) &
    #         Q(stage = round_order[match_index + 1]) &
    #         (Q(team1 = winning_team) | Q(team2 = winning_team))
    #     )

class Prediction(BuildableModel):
    season = models.IntegerField()
    stagecode = models.CharField(max_length=15)
    tieid = models.CharField(max_length=20)
    t1win = models.BooleanField(null=True)
    is_goal = models.BooleanField(null=True)
    is_away_goal = models.BooleanField(null=True)
    is_red_card = models.BooleanField(null=True)
    # probh1 = models.FloatField(null=True)
    # probd1 = models.FloatField(null=True)
    # proba1 = models.FloatField(null=True)
    minuteclean = models.IntegerField()
    minuterown = models.IntegerField()
    goalst1 = models.IntegerField()
    goalst2 = models.IntegerField()
    awaygoalst1 = models.IntegerField()
    awaygoalst2 = models.IntegerField()
    playerst1 = models.IntegerField()
    playerst2 = models.IntegerField()
    # goalst1diff = models.IntegerField()
    # awaygoalst1diff = models.IntegerField()
    # redcardst1diff = models.IntegerField()
    eventteam = models.IntegerField(null=True)
    player = models.CharField(max_length=50, null=True)
    playerid = models.CharField(max_length=20, null=True)
    eventtype = models.CharField(max_length=20, null=True)
    actualminute = models.CharField(max_length=10, null=True)
    predictedprobt1 = models.FloatField(null=True)
    likelihood = models.FloatField(null=True)
    error = models.FloatField(null=True)
    sqerror = models.FloatField(null=True)
    chgpredictedprobt1 = models.FloatField(null=True)

    objects = CopyManager()

    def get_predictedprobt2(self):
        return 1 - self.predictedprobt1

    def get_tie(self):
        return Tie.objects.filter(
            season=self.season,
            stagecode=self.stagecode,
            tieid=self.tieid
        )
