from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase
from django.test import TestCase

from apps.users.models import User
from .models import Audio


class AudioModelTest(TestCase):
    """Phase 2 — Modèle Audio."""

    def test_str(self):
        audio = Audio(titre='Conférence sur la foi')
        self.assertEqual(str(audio), 'Conférence sur la foi')

    def test_creation(self):
        audio = Audio.objects.create(
            titre='Test Audio',
            fichier='audios/test.mp3',
            date_publication=timezone.now(),
            is_published=True,
        )
        self.assertEqual(audio.titre, 'Test Audio')
        self.assertTrue(audio.is_published)


class AudioAPITest(APITestCase):
    """Phase 5 — API /api/audios/"""

    def setUp(self):
        self.admin = User.objects.create_superuser(
            username='admin', email='admin@test.com', password='pass'
        )
        self.publie = Audio.objects.create(
            titre='Audio Publié',
            fichier='audios/publie.mp3',
            date_publication=timezone.now(),
            is_published=True,
        )
        self.non_publie = Audio.objects.create(
            titre='Audio Non Publié',
            fichier='audios/non_publie.mp3',
            date_publication=timezone.now(),
            is_published=False,
        )

    def test_liste_accessible_sans_auth(self):
        response = self.client.get('/api/audios/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_public_voit_seulement_publies(self):
        response = self.client.get('/api/audios/')
        titres = [a['titre'] for a in response.data['results']]
        self.assertIn('Audio Publié', titres)
        self.assertNotIn('Audio Non Publié', titres)

    def test_admin_voit_tout(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/audios/')
        self.assertEqual(response.data['count'], 2)

    def test_creation_sans_auth_interdit(self):
        response = self.client.post('/api/audios/', {})
        self.assertIn(response.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])

    def test_detail_audio_publie_accessible(self):
        response = self.client.get(f'/api/audios/{self.publie.id}/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
