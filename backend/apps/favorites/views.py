from rest_framework import status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet
from django.contrib.contenttypes.models import ContentType
from .models import Favori
from .serializers import FavoriSerializer

_TYPE_MAP = {
    'audio': ('audios', 'audio'),
    'video': ('videos', 'video'),
    'citation': ('citations', 'citation'),
    'biographie': ('biographies', 'biographie'),
}


class FavoriViewSet(ModelViewSet):
    serializer_class = FavoriSerializer
    permission_classes = [IsAuthenticated]
    # Permet à drf-spectacular d'inférer le modèle/type du paramètre d'URL.
    # get_queryset() reste la source de vérité et filtre par utilisateur.
    queryset = Favori.objects.all()

    def get_queryset(self):
        # Anonyme lors de la génération du schéma : éviter une erreur d'introspection.
        if getattr(self, 'swagger_fake_view', False) or not self.request.user.is_authenticated:
            return Favori.objects.none()
        return Favori.objects.filter(user=self.request.user)

    @action(detail=False, methods=['post'], url_path='toggle')
    def toggle(self, request):
        type_name = request.data.get('type')
        object_id = request.data.get('object_id')

        if not type_name or not object_id:
            return Response(
                {'error': 'type et object_id sont requis'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if type_name not in _TYPE_MAP:
            return Response(
                {'error': 'Type invalide. Valeurs acceptées : audio, video, citation, biographie'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        app_label, model = _TYPE_MAP[type_name]
        try:
            content_type = ContentType.objects.get(app_label=app_label, model=model)
        except ContentType.DoesNotExist:
            return Response(
                {'error': 'ContentType introuvable'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        favori = Favori.objects.filter(
            user=request.user,
            content_type=content_type,
            object_id=object_id,
        ).first()

        if favori:
            favori.delete()
            return Response({'is_favorited': False}, status=status.HTTP_200_OK)

        Favori.objects.create(
            user=request.user,
            content_type=content_type,
            object_id=object_id,
        )
        return Response({'is_favorited': True}, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'], url_path='ids')
    def ids(self, request):
        type_name = request.query_params.get('type')
        queryset = self.get_queryset()

        if type_name and type_name in _TYPE_MAP:
            app_label, model = _TYPE_MAP[type_name]
            try:
                content_type = ContentType.objects.get(app_label=app_label, model=model)
                queryset = queryset.filter(content_type=content_type)
            except ContentType.DoesNotExist:
                return Response({'ids': []})

        object_ids = list(queryset.values_list('object_id', flat=True))
        return Response({'ids': object_ids})
