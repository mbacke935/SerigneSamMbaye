from django.db.models import Q
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.audios.models import Audio
from apps.audios.serializers import AudioSerializer
from apps.biographies.models import Biographie
from apps.biographies.serializers import BiographieSerializer
from apps.citations.models import Citation
from apps.citations.serializers import CitationSerializer
from apps.videos.models import Video
from apps.videos.serializers import VideoSerializer


class SearchView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        query = request.query_params.get('q', '').strip()
        if len(query) < 2:
            return Response({'detail': 'La recherche doit contenir au moins 2 caractères.'}, status=400)

        ctx = {'request': request}

        audios = Audio.objects.filter(
            Q(titre__icontains=query) | Q(description__icontains=query),
            is_published=True
        )[:10]

        videos = Video.objects.filter(
            Q(titre__icontains=query) | Q(description__icontains=query),
            is_published=True
        )[:10]

        citations = Citation.objects.filter(
            Q(texte__icontains=query) | Q(source__icontains=query),
            is_published=True
        )[:10]

        biographies = Biographie.objects.filter(
            Q(titre__icontains=query) | Q(contenu__icontains=query)
        )[:5]

        return Response({
            'query': query,
            'resultats': {
                'audios': AudioSerializer(audios, many=True, context=ctx).data,
                'videos': VideoSerializer(videos, many=True, context=ctx).data,
                'citations': CitationSerializer(citations, many=True).data,
                'biographies': BiographieSerializer(biographies, many=True, context=ctx).data,
            }
        })
