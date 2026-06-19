from django.db import models

from config.media_processing import compress_audio, is_new_upload


class Audio(models.Model):
    titre = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    fichier = models.FileField(upload_to='audios/')
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
        # Compresse uniquement les fichiers fraîchement téléversés ; une simple
        # modification du titre ne déclenche pas de ré-encodage.
        if is_new_upload(self.fichier):
            compressed = compress_audio(self.fichier)
            if compressed is not None:
                self.fichier = compressed
        super().save(*args, **kwargs)

    def __str__(self):
        return self.titre
