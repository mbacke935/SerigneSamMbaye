"""Génère des miniatures automatiques pour les vidéos qui n'en ont pas.

Flux normal :
    python manage.py generate_video_thumbnails

Nettoyer les miniatures pointant vers des fichiers absents du stockage,
puis regenerer (utile apres avoir exporte localement vers une DB de prod) :
    python manage.py generate_video_thumbnails --reset-broken

Traiter une seule video :
    python manage.py generate_video_thumbnails --id 42
"""
from django.core.management.base import BaseCommand

from apps.videos.models import Video
from config.video_thumbnail import extract_frame_from_url, youtube_thumbnail_url


class Command(BaseCommand):
    help = 'Génère des miniatures pour les vidéos sans image_miniature.'

    def add_arguments(self, parser):
        parser.add_argument('--id', type=int, default=None,
                            help="ID d'une seule vidéo à traiter.")
        parser.add_argument('--reset-broken', action='store_true', default=False,
                            help='Efface les chemins de miniature dont le fichier '
                                 "n'existe pas dans le stockage actuel, "
                                 'puis regenere pour ces videos.')

    def handle(self, *args, **options):
        if options['reset_broken']:
            self._clear_broken()

        qs = Video.objects.filter(image_miniature='')
        if options['id']:
            qs = qs.filter(pk=options['id'])

        total = qs.count()
        self.stdout.write(f'{total} video(s) sans miniature a traiter...')

        ok = skip = fail = 0

        for video in qs:
            url = video.lien_externe or ''

            # YouTube : miniature servie dynamiquement par le serializer
            if youtube_thumbnail_url(url):
                self.stdout.write(f'  [YOUTUBE] {video.titre} - OK (miniature via URL)')
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

    def _clear_broken(self):
        """Efface image_miniature quand le fichier n'existe pas dans le stockage."""
        self.stdout.write('Verification des miniatures existantes...')
        qs = Video.objects.exclude(image_miniature='').exclude(image_miniature__isnull=True)
        cleared = 0
        for v in qs:
            try:
                exists = v.image_miniature.storage.exists(v.image_miniature.name)
            except Exception as exc:
                self.stdout.write(f'  [ERREUR] {v.titre}: {exc}')
                continue
            if not exists:
                v.image_miniature = None
                v.save(update_fields=['image_miniature'])
                self.stdout.write(f'  [RESET]  {v.titre} - fichier absent du stockage')
                cleared += 1
        self.stdout.write(f'{cleared} miniature(s) invalide(s) effacee(s).\n')
