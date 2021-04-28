from django.conf import settings
from winprob.models import Tie

def live_ties(request):
    live_ties = Tie.objects.filter(in_progress=True)
    if len(live_ties) > 4:
        live_ties = live_ties[:4]
    return {
        "live_ties": live_ties,
    }
