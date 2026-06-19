from django.db import models


class Audio(models.Model):
    titre = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    fichier = models.FileField(upload_to='audios/')
    image_miniature = models.ImageField(upload_to='miniatures/audios/', blank=True, null=True)
    duree = models.DurationField(blank=True, null=True)
    date_publication = models.DateTimeField()
    is_published = models.BooleanField(default=False)
    date_creation = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Audio'
        verbose_name_plural = 'Audios'
        ordering = ['-date_publication']

    def __str__(self):
        return self.titre
