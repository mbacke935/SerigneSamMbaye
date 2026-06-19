from rest_framework.viewsets import ModelViewSet

from config.permissions import IsAdminOrReadOnly
from .models import Album
from .serializers import AlbumSerializer, AlbumDetailSerializer


class AlbumViewSet(ModelViewSet):
    permission_classes = [IsAdminOrReadOnly]

    def get_queryset(self):
        qs = Album.objects.all()
        if not (self.request.user and self.request.user.is_staff):
            qs = qs.filter(is_published=True)
        return qs.order_by('ordre', '-date_creation')

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return AlbumDetailSerializer
        return AlbumSerializer
