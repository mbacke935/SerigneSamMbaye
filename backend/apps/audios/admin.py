from django.contrib import admin
from .models import Audio


@admin.register(Audio)
class AudioAdmin(admin.ModelAdmin):
    list_display = ('titre', 'date_publication', 'duree', 'is_published', 'date_creation')
    list_filter = ('is_published',)
    list_editable = ('is_published',)
    search_fields = ('titre', 'description')
    date_hierarchy = 'date_publication'
    readonly_fields = ('date_creation',)

    fieldsets = (
        ('Informations', {
            'fields': ('titre', 'description', 'date_publication', 'is_published')
        }),
        ('Fichiers', {
            'fields': ('fichier', 'image_miniature', 'duree')
        }),
        ('Métadonnées', {
            'fields': ('date_creation',)
        }),
    )
