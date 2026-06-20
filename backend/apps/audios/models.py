from django.conf import settings
from django.db import models

from config.media_processing import compress_audio, is_new_upload, normalize_external_url
from config.storage import audio_storage


class Audio(models.Model):
    titre = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    fichier = models.FileField(upload_to='audios/', storage=audio_storage, blank=True)
    lien_externe = models.URLField(
        max_length=500, blank=True,
        help_text="URL directe d'un audio hébergé ailleurs (ex. Internet Archive .mp3). "
                  "Prioritaire sur le fichier si renseigné.",
    )
    image_miniature = models.ImageField(upload_to='miniatures/audios/', blank=True, null=True)
    album = models.ForeignKey(
        'albums.Album', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='audios',
    )
    duree = models.DurationField(blank=True, null=True)
    date_publication = models.DateTimeField()
    is_published = models.BooleanField(default=False)
    date_creation = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Audio'
        verbose_name_plural = 'Audios'
        ordering = ['-date_publication']

    def save(self, *args, **kwargs):
        # Normalise le lien externe (espaces/accents → %XX) pour que les lecteurs
        # puissent le charger. Idempotent : un lien déjà encodé reste inchangé.
        if self.lien_externe:
            self.lien_externe = normalize_external_url(self.lien_externe)
        # Compresse uniquement si activé (COMPRESS_AUDIO) ET fichier fraîchement
        # téléversé. Désactivé par défaut car trop lourd pour Render gratuit
        # (le worker se fait tuer par l'OOM killer → upload en 500).
        if getattr(settings, 'COMPRESS_AUDIO', False) and is_new_upload(self.fichier):
            compressed = compress_audio(self.fichier)
            if compressed is not None:
                self.fichier = compressed
        super().save(*args, **kwargs)

    def __str__(self):
        return self.titre
