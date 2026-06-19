import datetime
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from apps.audios.models import Audio
from apps.biographies.models import Biographie
from apps.citations.models import Citation
from apps.videos.models import Video


class SearchAPITest(APITestCase):
    """Phase 5 — API /api/search/"""

    def setUp(self):
        self.audio = Audio.objects.create(
            titre='Conférence sur la Mouridiyya',
            description='Enseignement spirituel',
            fichier='audios/conference.mp3',
            date_publication=timezone.now(),
            is_published=True,
        )
        self.video = Video.objects.create(
            titre='Khassida en vidéo',
            description='Récitation des khassidas',
            fichier='videos/khassida.mp4',
            date_publication=timezone.now(),
            is_published=True,
        )
        self.citation = Citation.objects.create(
            texte='La patience est une vertu divine',
            date_publication=datetime.date.today(),
            is_published=True,
        )
        self.biographie = Biographie.objects.create(
            titre='Vie de Serigne Sam Mbaye',
            contenu='Grand marabout mouride du Sénégal',
        )
        # Contenu non publié — ne doit pas apparaître dans les résultats
        Audio.objects.create(
            titre='Conférence privée',
            fichier='audios/prive.mp3',
            date_publication=timezone.now(),
            is_published=False,
        )

    def test_recherche_accessible_sans_auth(self):
        response = self.client.get('/api/search/?q=conference')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_recherche_retourne_structure_correcte(self):
        response = self.client.get('/api/search/?q=conference')
        self.assertIn('query', response.data)
        self.assertIn('resultats', response.data)
        self.assertIn('audios', response.data['resultats'])
        self.assertIn('videos', response.data['resultats'])
        self.assertIn('citations', response.data['resultats'])
        self.assertIn('biographies', response.data['resultats'])

    def test_recherche_trouve_audio(self):
        response = self.client.get('/api/search/?q=Mouridiyya')
        audios = response.data['resultats']['audios']
        self.assertEqual(len(audios), 1)
        self.assertEqual(audios[0]['titre'], 'Conférence sur la Mouridiyya')

    def test_recherche_trouve_video(self):
        response = self.client.get('/api/search/?q=khassida')
        videos = response.data['resultats']['videos']
        self.assertEqual(len(videos), 1)

    def test_recherche_trouve_citation(self):
        response = self.client.get('/api/search/?q=patience')
        citations = response.data['resultats']['citations']
        self.assertEqual(len(citations), 1)

    def test_recherche_trouve_biographie(self):
        response = self.client.get('/api/search/?q=Serigne')
        biographies = response.data['resultats']['biographies']
        self.assertEqual(len(biographies), 1)

    def test_recherche_exclut_non_publies(self):
        response = self.client.get('/api/search/?q=privée')
        audios = response.data['resultats']['audios']
        titres = [a['titre'] for a in audios]
        self.assertNotIn('Conférence privée', titres)

    def test_requete_trop_courte_retourne_400(self):
        response = self.client.get('/api/search/?q=a')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_requete_vide_retourne_400(self):
        response = self.client.get('/api/search/?q=')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_recherche_insensible_a_la_casse(self):
        response = self.client.get('/api/search/?q=MOURIDIYYA')
        audios = response.data['resultats']['audios']
        self.assertEqual(len(audios), 1)
