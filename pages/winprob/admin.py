from django.contrib import admin

# Register your models here.

from .models import Competition, Team

admin.site.register(Competition)
admin.site.register(Team)