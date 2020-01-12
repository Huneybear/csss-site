from django.shortcuts import render

# Create your views here.
# from django.views import generic

from .models import NominationPage, Nominee
from datetime import datetime

import logging
logger = logging.getLogger('csss_site')


def get_nominees(request, slug):
    groups = list(request.user.groups.values_list('name', flat=True))
    retrieved_obj = NominationPage.objects.filter(slug=slug)
    if retrieved_obj[0].date <= datetime.now():
        logger.info(f"[elections/views.py get_nominees()] time to vote")
        nominees = Nominee.objects.filter(nomination_page__slug=slug).all().order_by('position')
        context = {
            'election': retrieved_obj[0],
            'election_date': retrieved_obj[0].date.strftime("%Y-%m-%d"),
            'tab': 'elections',
            'authenticated': request.user.is_authenticated,
            'nominees': nominees,
            'Exec': ('Exec' in groups),
            'ElectionOfficer': ('ElectionOfficer' in groups),
            'Staff': request.user.is_staff,
            'Username': request.user.username
        }
        return render(request, 'elections/nominee_list.html', context)
    else:
        logger.info(f"[elections/views.py get_nominees()] cant vote yet")
        context = {
            'tab': 'elections',
            'nominees': 'none',
            'authenticated': request.user.is_authenticated,
            'Exec': ('Exec' in groups),
            'ElectionOfficer': ('ElectionOfficer' in groups),
            'Staff': request.user.is_staff,
            'Username': request.user.username
        }
        return render(request, 'elections/nominee_list.html', context)
