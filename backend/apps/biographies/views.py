from rest_framework.viewsets import ModelViewSet
from config.permissions import IsAdminOrReadOnly
from .models import Biographie
from .serializers import BiographieSerializer


class BiographieViewSet(ModelViewSet):
    queryset = Biographie.objects.all().order_by('-date_creation')
    serializer_class = BiographieSerializer
    permission_classes = [IsAdminOrReadOnly]
