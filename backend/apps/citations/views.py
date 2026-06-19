from django.utils import timezone
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet
from config.permissions import IsAdminOrReadOnly
from .models import Citation
from .serializers import CitationSerializer


class CitationViewSet(ModelViewSet):
    serializer_class = CitationSerializer
    permission_classes = [IsAdminOrReadOnly]

    def get_queryset(self):
        qs = Citation.objects.all()
        if not (self.request.user and self.request.user.is_staff):
            qs = qs.filter(is_published=True)
        return qs.order_by('-date_publication', '-date_creation')

    @action(detail=False, methods=['get'], url_path='du_jour')
    def du_jour(self, request):
        """Retourne la citation publiée la plus récente à la date d'aujourd'hui."""
        aujourd_hui = timezone.now().date()
        citation = (
            Citation.objects
            .filter(is_published=True, date_publication__lte=aujourd_hui)
            .order_by('-date_publication')
            .first()
        )
        if not citation:
            return Response({'detail': 'Aucune citation disponible.'}, status=404)
        return Response(CitationSerializer(citation).data)
