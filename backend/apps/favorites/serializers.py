from rest_framework import serializers
from django.contrib.contenttypes.models import ContentType
from .models import Favori


class FavoriSerializer(serializers.ModelSerializer):
    type_contenu = serializers.SerializerMethodField()
    objet = serializers.SerializerMethodField()

    class Meta:
        model = Favori
        fields = ['id', 'content_type', 'object_id', 'type_contenu', 'objet', 'date_ajout']
        read_only_fields = ['date_ajout', 'type_contenu', 'objet']

    def get_type_contenu(self, obj):
        return obj.content_type.model

    def get_objet(self, obj):
        # Lazy imports to avoid circular dependencies
        from apps.audios.serializers import AudioSerializer
        from apps.videos.serializers import VideoSerializer
        from apps.citations.serializers import CitationSerializer
        from apps.biographies.serializers import BiographieSerializer

        content = obj.content_object
        if content is None:
            return None

        serializer_map = {
            'audio': AudioSerializer,
            'video': VideoSerializer,
            'citation': CitationSerializer,
            'biographie': BiographieSerializer,
        }
        cls = serializer_map.get(obj.content_type.model)
        if cls is None:
            return None
        return cls(content, context=self.context).data

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)
