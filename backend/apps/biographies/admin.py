from django.contrib import admin
from .models import Biographie


@admin.register(Biographie)
class BiographieAdmin(admin.ModelAdmin):
    list_display = ('titre', 'date_creation', 'date_modification')
    search_fields = ('titre', 'contenu')
    readonly_fields = ('date_creation', 'date_modification')

    fieldsets = (
        ('Contenu', {'fields': ('titre', 'contenu')}),
        ('Média', {'fields': ('image',)}),
        ('Dates', {'fields': ('date_creation', 'date_modification')}),
    )
