"""Encode les `lien_externe` déjà présents en base (audios + vidéos).

La normalisation côté modèle ne s'applique qu'aux prochains enregistrements ;
cette commande corrige le contenu existant. Les liens Internet Archive avec
espaces/accents (ex. « s.sam 56.mp3 ») deviennent chargeables par les lecteurs.

Usage :
    python manage.py normalize_external_links --dry-run   # aperçu, n'écrit rien
    python manage.py normalize_external_links             # applique les changements
"""
from django.core.management.base import BaseCommand

from apps.audios.models import Audio
from apps.videos.models import Video
from config.media_processing import normalize_external_url


class Command(BaseCommand):
    help = "Encode les lien_externe existants (espaces/accents) des audios et vidéos."

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run', action='store_true',
            help="Affiche les changements sans rien enregistrer.",
        )

    def handle(self, *args, **options):
        dry = options['dry_run']
        total = 0
        for model in (Audio, Video):
            label = model._meta.verbose_name
            qs = model.objects.exclude(lien_externe='').exclude(lien_externe__isnull=True)
            for obj in qs:
                old = obj.lien_externe
                new = normalize_external_url(old)
                if new == old:
                    continue
                total += 1
                self.stdout.write(f'[{label} #{obj.id}] {old}  ->  {new}')
                if not dry:
                    obj.lien_externe = new
                    # update_fields : ne touche que la colonne du lien (évite toute
                    # re-compression ou ré-écriture du fichier média).
                    obj.save(update_fields=['lien_externe'])

        if dry:
            self.stdout.write(self.style.WARNING(
                f'{total} lien(s) à corriger (dry-run : rien enregistré).'))
        else:
            self.stdout.write(self.style.SUCCESS(f'{total} lien(s) corrigé(s).'))
