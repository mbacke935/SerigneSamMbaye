from django.contrib import admin

from .models import Album


@admin.register(Album)
class AlbumAdmin(admin.ModelAdmin):
    list_display = ('titre', 'ordre', 'is_published', 'date_creation')
    list_filter = ('is_published',)
    list_editable = ('ordre', 'is_published')
    search_fields = ('titre', 'description')
    readonly_fields = ('date_creation',)
