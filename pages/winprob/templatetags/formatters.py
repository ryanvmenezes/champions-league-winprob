from django import template
from django.template.defaultfilters import stringfilter

import markdown2 as md

register = template.Library()

@register.filter
def format_predictedprob(value):
    if value > 0.5:
        return round(value * 100, 1)
    if value < 0.5:
        return round((1 - value) * 100, 1)
    if value == 0.5:
        return 50.0

@register.filter
def format_chgprob(value):
    if value > 0:
        return round(value * 100, 1)
    if value < 0:
        return round(abs(value) * 100, 1)
    if value == 0.5:
        return 0.0

@register.filter
def format_abschgprob(value):
    return f'+{round(value * 100, 1)}%'

@register.filter
def format_percent_one_decimal(value):
    return round(value * 100, 1)

@register.filter
def format_minutes(value):
    for m in ['45+', '90+', '105+', '120+']:
        if m in value:
            return value.replace('+', "’+") + "’"
    # if '90' in value or '45' in value or '120' in value or '105' in value:
    #     return value.replace('90', "90’")
    return value + "’"

@register.filter
@stringfilter
def markdown(value):
    return md.markdown(value)
