import os
import csv
from tqdm import tqdm
from django.conf import settings
from django.utils.text import slugify
from django.core.management.base import BaseCommand

from winprob.models import *

class Command(BaseCommand):
    def handle(self, *args, **options):
        posts_dir = os.path.join(settings.BASE_DIR, 'winprob', 'posts')
        posts_paths = os.listdir(posts_dir)
        for path in posts_paths:
            slug = path.replace('.md', '')
            with open(os.path.join(posts_dir, path), 'r') as f:
                md = ''.join(f.readlines())
                post, post_created = Post.objects.get_or_create(slug=slug)
                if not post_created:
                    post.body = md
                    post.save()
                else:
                    print(f"No post with slug: {slug}")
