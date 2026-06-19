from django.contrib import admin
from .models import Favori


@admin.register(Favori)
class FavoriAdmin(admin.ModelAdmin):
    list_display = ('user', 'content_type', 'object_id', 'date_ajout')
    list_filter = ('content_type',)
    search_fields = ('user__email',)
    readonly_fields = ('date_ajout',)
