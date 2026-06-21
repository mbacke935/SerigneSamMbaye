from rest_framework import serializers

from config.video_thumbnail import youtube_thumbnail_url

from .models import Video


class VideoSerializer(serializers.ModelSerializer):
    image_miniature = serializers.SerializerMethodField()

    def get_image_miniature(self, obj: Video):
        # 1. Miniature uploadée manuellement → priorité absolue
        if obj.image_miniature:
            request = self.context.get('request')
            try:
                url = obj.image_miniature.url
                return request.build_absolute_uri(url) if request else url
            except Exception:
                pass

        # 2. Vidéo YouTube → miniature officielle gratuite
        src = obj.lien_externe or ''
        yt = youtube_thumbnail_url(src)
        if yt:
            return yt

        return None

    class Meta:
        model = Video
        fields = '__all__'
