from django.db import models


class Album(models.Model):
    """Collection thématique regroupant des audios et/ou des vidéos."""
    titre = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    image = models.ImageField(upload_to='albums/', blank=True, null=True)
    is_published = models.BooleanField(default=True)
    ordre = models.PositiveIntegerField(default=0, help_text="Ordre d'affichage (croissant)")
    date_creation = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Album'
        verbose_name_plural = 'Albums'
        ordering = ['ordre', '-date_creation']

    def __str__(self):
        return self.titre
