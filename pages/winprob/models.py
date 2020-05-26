from django.db import models

# Create your models here.

class Competition(models.Model):
    COMPETITION_CHOICES = [
        ('cl', 'UEFA Champions League'),
        ('el', 'UEFA Europa League'),
    ]
    competition_name = models.CharField(
        max_length=5,
        choices=COMPETITION_CHOICES
    )

class Team(models.Model):
    team_name = models.CharField(max_length=50)
    team_slug = models.CharField(max_length=50)
    country = models.CharField(max_length=50)
    fbrefid = models.CharField(max_length=10)
    # other_names = models.CharField(max_length=100)

