from rest_framework.viewsets import ModelViewSet
from config.permissions import IsAdminOrReadOnly
from .models import Video
from .serializers import VideoSerializer


class VideoViewSet(ModelViewSet):
    serializer_class = VideoSerializer
    permission_classes = [IsAdminOrReadOnly]

    def get_queryset(self):
        qs = Video.objects.all()
        if not (self.request.user and self.request.user.is_staff):
            qs = qs.filter(is_published=True)
        return qs.order_by('-date_publication', '-date_creation')
