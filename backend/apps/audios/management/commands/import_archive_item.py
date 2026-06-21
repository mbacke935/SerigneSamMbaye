"""Importe tous les fichiers audio d'un item Internet Archive.

L'API publique d'Archive.org (sans authentification) est utilisée :
  https://archive.org/metadata/{identifier}

Usage :
    python manage.py import_archive_item 10_ser_sam_mbaye07
    python manage.py import_archive_item 10_ser_sam_mbaye07 --album-id 3
    python manage.py import_archive_item 10_ser_sam_mbaye07 --published --dry-run
"""
import json
import urllib.parse
import urllib.request
from datetime import timedelta

from django.core.management.base import BaseCommand, CommandError
from django.utils.timezone import now

from apps.audios.models import Audio

AUDIO_FORMATS = {'mp3', 'vbr mp3', 'ogg vorbis', 'flac', '128kbps mp3', '64kbps mp3'}


def _parse_duration(length_str: str):
    """Convertit la durée Archive.org (secondes float ou HH:MM:SS) en timedelta."""
    if not length_str:
        return None
    try:
        return timedelta(seconds=float(length_str))
    except ValueError:
        pass
    try:
        parts = [int(p) for p in length_str.split(':')]
        if len(parts) == 3:
            return timedelta(hours=parts[0], minutes=parts[1], seconds=parts[2])
        if len(parts) == 2:
            return timedelta(minutes=parts[0], seconds=parts[1])
    except (ValueError, IndexError):
        pass
    return None


class Command(BaseCommand):
    help = "Importe les fichiers audio d'un item Internet Archive."

    def add_arguments(self, parser):
        parser.add_argument('identifier', help="Identifiant Archive.org (ex: 10_ser_sam_mbaye07)")
        parser.add_argument('--album-id', type=int, dest='album_id',
                            help="ID de l'album auquel associer les audios créés")
        parser.add_argument('--published', action='store_true', default=False,
                            help="Marquer les audios comme publiés (is_published=True)")
        parser.add_argument('--dry-run', action='store_true',
                            help="Affiche ce qui serait créé sans rien enregistrer")

    def handle(self, *args, **options):
        identifier = options['identifier']
        dry = options['dry_run']
        published = options['published']
        album_id = options.get('album_id')

        metadata_url = f'https://archive.org/metadata/{identifier}'
        self.stdout.write(f'Récupération de {metadata_url}…')
        try:
            with urllib.request.urlopen(metadata_url, timeout=30) as r:
                data = json.loads(r.read())
        except Exception as exc:
            raise CommandError(f'Impossible de récupérer les métadonnées : {exc}')

        if not data.get('files'):
            raise CommandError(f'Aucun fichier trouvé pour « {identifier} ».')

        album = None
        if album_id:
            try:
                from apps.albums.models import Album
                album = Album.objects.get(pk=album_id)
                self.stdout.write(f'Album cible : {album}')
            except Exception:
                raise CommandError(f'Album id={album_id} introuvable.')

        base_url = f'https://archive.org/download/{identifier}/'
        files = data['files']

        # Garder uniquement les fichiers audio originaux (pas les dérivés)
        audio_files = [
            f for f in files
            if f.get('source') == 'original'
            and f.get('format', '').lower() in AUDIO_FORMATS
        ]
        if not audio_files:
            # Fallback si tous sont marqués 'derivative' (cas rare)
            audio_files = [
                f for f in files
                if f.get('format', '').lower() in AUDIO_FORMATS
            ]

        if not audio_files:
            self.stdout.write(self.style.WARNING('Aucun fichier audio trouvé dans cet item.'))
            return

        self.stdout.write(f'{len(audio_files)} fichier(s) audio détecté(s).\n')

        created = skipped = 0
        for f in sorted(audio_files, key=lambda x: x.get('name', '')):
            name = f.get('name', '')
            if not name:
                continue

            lien_externe = base_url + urllib.parse.quote(name)
            titre = name.rsplit('.', 1)[0].replace('_', ' ').replace('-', ' ').strip()
            duree = _parse_duration(f.get('length', ''))

            if Audio.objects.filter(lien_externe=lien_externe).exists():
                self.stdout.write(f'  [EXISTANT]  {name}')
                skipped += 1
                continue

            flag = '[DRY-RUN]' if dry else '[CRÉER]'
            dur_str = str(duree).split('.')[0] if duree else '—'
            self.stdout.write(f'  {flag}  {titre}  ({dur_str})')

            if not dry:
                audio = Audio.objects.create(
                    titre=titre,
                    lien_externe=lien_externe,
                    duree=duree,
                    date_publication=now(),
                    is_published=published,
                    album=album,
                )
                created += 1
                _ = audio  # silence unused warning

        if dry:
            self.stdout.write(self.style.WARNING(
                f'\n{len(audio_files) - skipped} à créer, {skipped} déjà présent(s) — dry-run, rien enregistré.'
            ))
        else:
            self.stdout.write(self.style.SUCCESS(
                f'\n{created} audio(s) créé(s), {skipped} déjà présent(s).'
            ))
