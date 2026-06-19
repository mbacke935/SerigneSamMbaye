from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase
from django.test import TestCase

from apps.users.models import User
from .models import Video


class VideoModelTest(TestCase):
    """Phase 2 — Modèle Video."""

    def test_str(self):
        video = Video(titre='Khassida en vidéo')
        self.assertEqual(str(video), 'Khassida en vidéo')

    def test_creation(self):
        video = Video.objects.create(
            titre='Test Vidéo',
            fichier='videos/test.mp4',
            date_publication=timezone.now(),
            is_published=True,
        )
        self.assertEqual(video.titre, 'Test Vidéo')
        self.assertFalse(video.is_published is None)


class VideoAPITest(APITestCase):
    """Phase 5 — API /api/videos/"""

    def setUp(self):
        self.admin = User.objects.create_superuser(
            username='admin', email='admin@test.com', password='pass'
        )
        self.publie = Video.objects.create(
            titre='Vidéo Publiée',
            fichier='videos/publie.mp4',
            date_publication=timezone.now(),
            is_published=True,
        )
        self.non_publie = Video.objects.create(
            titre='Vidéo Non Publiée',
            fichier='videos/non_publie.mp4',
            date_publication=timezone.now(),
            is_published=False,
        )

    def test_liste_accessible_sans_auth(self):
        response = self.client.get('/api/videos/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_public_voit_seulement_publiees(self):
        response = self.client.get('/api/videos/')
        titres = [v['titre'] for v in response.data['results']]
        self.assertIn('Vidéo Publiée', titres)
        self.assertNotIn('Vidéo Non Publiée', titres)

    def test_admin_voit_tout(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/videos/')
        self.assertEqual(response.data['count'], 2)

    def test_creation_sans_auth_interdit(self):
        response = self.client.post('/api/videos/', {})
        self.assertIn(response.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])
