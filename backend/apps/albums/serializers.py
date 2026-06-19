from rest_framework import serializers
from drf_spectacular.utils import extend_schema_field

from .models import Album


class AlbumSerializer(serializers.ModelSerializer):
    """Vue liste : album + nombre d'éléments publiés."""
    nb_audios = serializers.SerializerMethodField()
    nb_videos = serializers.SerializerMethodField()

    class Meta:
        model = Album
        fields = ['id', 'titre', 'description', 'image', 'ordre',
                  'nb_audios', 'nb_videos', 'date_creation']

    @extend_schema_field(serializers.IntegerField())
    def get_nb_audios(self, obj) -> int:
        return obj.audios.filter(is_published=True).count()

    @extend_schema_field(serializers.IntegerField())
    def get_nb_videos(self, obj) -> int:
        return obj.videos.filter(is_published=True).count()


class AlbumDetailSerializer(AlbumSerializer):
    """Vue détail : album + ses audios et vidéos publiés."""
    audios = serializers.SerializerMethodField()
    videos = serializers.SerializerMethodField()

    class Meta(AlbumSerializer.Meta):
        fields = AlbumSerializer.Meta.fields + ['audios', 'videos']

    @extend_schema_field(serializers.ListField())
    def get_audios(self, obj):
        from apps.audios.serializers import AudioSerializer
        qs = obj.audios.filter(is_published=True).order_by('-date_publication')
        return AudioSerializer(qs, many=True, context=self.context).data

    @extend_schema_field(serializers.ListField())
    def get_videos(self, obj):
        from apps.videos.serializers import VideoSerializer
        qs = obj.videos.filter(is_published=True).order_by('-date_publication')
        return VideoSerializer(qs, many=True, context=self.context).data
