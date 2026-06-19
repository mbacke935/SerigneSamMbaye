from django.db import models

from config.storage import video_storage


class Video(models.Model):
    titre = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    fichier = models.FileField(upload_to='videos/', storage=video_storage, blank=True)
    lien_externe = models.URLField(
        max_length=500, blank=True,
        help_text="URL directe d'une vidéo hébergée ailleurs (ex. Internet Archive .mp4). "
                  "Prioritaire sur le fichier si renseigné.",
    )
    image_miniature = models.ImageField(upload_to='miniatures/videos/', blank=True, null=True)
    album = models.ForeignKey(
        'albums.Album', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='videos',
    )
    duree = models.DurationField(blank=True, null=True)
    date_publication = models.DateTimeField()
    is_published = models.BooleanField(default=False)
    date_creation = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Vidéo'
        verbose_name_plural = 'Vidéos'
        ordering = ['-date_publication']

    def __str__(self):
        return self.titre
