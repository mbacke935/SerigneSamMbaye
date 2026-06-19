from django.contrib import admin
from .models import Audio


@admin.register(Audio)
class AudioAdmin(admin.ModelAdmin):
    list_display = ('titre', 'album', 'date_publication', 'duree', 'is_published', 'date_creation')
    list_filter = ('is_published', 'album')
    list_editable = ('is_published',)
    search_fields = ('titre', 'description')
    date_hierarchy = 'date_publication'
    readonly_fields = ('date_creation',)

    fieldsets = (
        ('Informations', {
            'fields': ('titre', 'description', 'album', 'date_publication', 'is_published')
        }),
        ('Fichiers', {
            'fields': ('lien_externe', 'fichier', 'image_miniature', 'duree'),
            'description': "Renseignez un <b>lien externe</b> (recommandé pour les gros "
                           "fichiers, ex. Internet Archive) <i>ou</i> téléversez un fichier.",
        }),
        ('Métadonnées', {
            'fields': ('date_creation',)
        }),
    )
