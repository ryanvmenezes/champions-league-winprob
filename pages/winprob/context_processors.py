from django.conf import settings
from winprob.models import Tie

def live_ties(request):
    return {
        "live_ties": Tie.objects.filter(in_progress=True)[:4],
    }
