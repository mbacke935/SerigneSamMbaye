from django.contrib import admin
from .models import Citation


@admin.register(Citation)
class CitationAdmin(admin.ModelAdmin):
    list_display = ('apercu', 'date_publication', 'is_published', 'date_creation')
    list_filter = ('is_published',)
    list_editable = ('is_published',)
    search_fields = ('texte', 'source')
    date_hierarchy = 'date_publication'
    readonly_fields = ('date_creation',)

    fieldsets = (
        ('Contenu', {'fields': ('texte', 'source')}),
        ('Publication', {'fields': ('date_publication', 'is_published')}),
        ('Métadonnées', {'fields': ('date_creation',)}),
    )

    @admin.display(description='Texte')
    def apercu(self, obj):
        return obj.texte[:80] + '…' if len(obj.texte) > 80 else obj.texte
