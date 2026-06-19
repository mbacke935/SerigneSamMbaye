from django.db import models


class Citation(models.Model):
    texte = models.TextField()
    source = models.CharField(max_length=200, blank=True)
    date_publication = models.DateField()
    is_published = models.BooleanField(default=False)
    date_creation = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Citation'
        verbose_name_plural = 'Citations'
        ordering = ['-date_publication']

    def __str__(self):
        return self.texte[:80]
