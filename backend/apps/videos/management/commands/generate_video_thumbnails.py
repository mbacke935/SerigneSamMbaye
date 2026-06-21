"""Génère des miniatures automatiques pour les vidéos qui n'en ont pas.

Usage :
    python manage.py generate_video_thumbnails            # toutes les vidéos sans miniature
    python manage.py generate_video_thumbnails --id 42   # une seule vidéo
"""
from django.core.management.base import BaseCommand

from apps.videos.models import Video
from config.video_thumbnail import extract_frame_from_url, youtube_thumbnail_url


class Command(BaseCommand):
    help = 'Génère des miniatures pour les vidéos sans image_miniature.'

    def add_arguments(self, parser):
        parser.add_argument('--id', type=int, default=None,
                            help='ID d\'une seule vidéo à traiter.')

    def handle(self, *args, **options):
        qs = Video.objects.filter(image_miniature='')
        if options['id']:
            qs = qs.filter(pk=options['id'])

        total = qs.count()
        self.stdout.write(f'{total} video(s) sans miniature a traiter...')

        ok = skip = fail = 0

        for video in qs:
            url = video.lien_externe or ''

            # YouTube → on s'appuie sur le serializer (URL externe), pas besoin de fichier
            if youtube_thumbnail_url(url):
                self.stdout.write(f'  [YOUTUBE] {video.titre} - miniature via serializer (OK)')
                skip += 1
                continue

            if not url:
                self.stdout.write(f'  [SKIP]    {video.titre} - aucune URL externe')
                skip += 1
                continue

            self.stdout.write(f'  [FFmpeg]  {video.titre}...', ending=' ')
            frame = extract_frame_from_url(url)
            if frame:
                video.image_miniature.save(f'thumb_{video.pk}.jpg', frame, save=True)
                self.stdout.write('OK')
                ok += 1
            else:
                self.stdout.write('ECHEC (FFmpeg)')
                fail += 1

        self.stdout.write(
            f'\nTermine : {ok} generee(s), {skip} ignoree(s), {fail} echouee(s).'
        )
