import urllib.parse
from datetime import date

from django.contrib import admin, messages
from django.shortcuts import render
from django.urls import path, reverse

from apps.albums.models import Album

from .models import Video


def _parse_lines(raw: str):
    """Yield (titre, url) from textarea lines. Format: URL or Titre | URL."""
    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        if '|' in line:
            parts = line.split('|', 1)
            titre = parts[0].strip()
            url = parts[1].strip()
        else:
            url = line
            path_part = urllib.parse.urlparse(url).path
            titre = urllib.parse.unquote(path_part.split('/')[-1])
            titre = titre.rsplit('.', 1)[0] if '.' in titre else titre
        if url:
            yield titre or url, url


@admin.register(Video)
class VideoAdmin(admin.ModelAdmin):
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
                           "fichiers, ex. Internet Archive / YouTube) <i>ou</i> téléversez un fichier.",
        }),
        ('Métadonnées', {
            'fields': ('date_creation',)
        }),
    )

    def get_urls(self):
        urls = super().get_urls()
        custom = [
            path('import-bulk/', self.admin_site.admin_view(self.bulk_import_view),
                 name='videos_video_bulk_import'),
        ]
        return custom + urls

    def changelist_view(self, request, extra_context=None):
        extra_context = extra_context or {}
        extra_context['bulk_import_url'] = reverse('admin:videos_video_bulk_import')
        return super().changelist_view(request, extra_context=extra_context)

    def bulk_import_view(self, request):
        list_url = reverse('admin:videos_video_changelist')
        results = None

        if request.method == 'POST':
            raw = request.POST.get('liens', '')
            album_id = request.POST.get('album') or None
            date_str = request.POST.get('date_publication', str(date.today()))
            is_published = bool(request.POST.get('is_published'))

            album = Album.objects.filter(pk=album_id).first() if album_id else None

            try:
                pub_date = date.fromisoformat(date_str)
            except ValueError:
                pub_date = date.today()

            created = 0
            skipped = 0
            errors = []

            for titre, url in _parse_lines(raw):
                try:
                    Video.objects.create(
                        titre=titre,
                        lien_externe=url,
                        album=album,
                        date_publication=pub_date,
                        is_published=is_published,
                    )
                    created += 1
                except Exception as exc:
                    errors.append(f'{titre}: {exc}')
                    skipped += 1

            results = {'created': created, 'skipped': skipped, 'errors': errors}
            if created:
                messages.success(request, f'{created} vidéo(s) importée(s) avec succès.')

        context = {
            **self.admin_site.each_context(request),
            'model_verbose_name_plural': 'Vidéos',
            'list_url': list_url,
            'albums': Album.objects.order_by('titre'),
            'default_date': str(date.today()),
            'default_published': False,
            'selected_album': None,
            'form_liens': '',
            'results': results,
            'title': 'Import en masse — Vidéos',
        }
        return render(request, 'admin/bulk_import.html', context)
