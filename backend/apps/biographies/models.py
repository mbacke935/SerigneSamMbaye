from django.db import models


class Biographie(models.Model):
    titre = models.CharField(max_length=200)
    contenu = models.TextField()
    image = models.ImageField(upload_to='biographies/', blank=True, null=True)
    date_creation = models.DateTimeField(auto_now_add=True)
    date_modification = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Biographie'
        verbose_name_plural = 'Biographies'

    def __str__(self):
        return self.titre
