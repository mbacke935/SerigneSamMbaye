from django.test import TestCase
from rest_framework import status
from rest_framework.test import APITestCase

from apps.users.models import User
from .models import Biographie


class BiographieModelTest(TestCase):
    """Phase 2 — Modèle Biographie."""

    def test_str(self):
        bio = Biographie(titre='Vie de Serigne Sam Mbaye')
        self.assertEqual(str(bio), 'Vie de Serigne Sam Mbaye')

    def test_creation(self):
        bio = Biographie.objects.create(titre='Test', contenu='Contenu détaillé')
        self.assertEqual(bio.titre, 'Test')
        self.assertIsNotNone(bio.date_creation)


class BiographieAPITest(APITestCase):
    """Phase 5 — API /api/biographies/"""

    def setUp(self):
        self.admin = User.objects.create_superuser(
            username='admin', email='admin@test.com', password='pass'
        )
        self.bio = Biographie.objects.create(
            titre='Biographie Test',
            contenu='Contenu de test',
        )

    def test_liste_accessible_sans_auth(self):
        response = self.client.get('/api/biographies/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_detail_accessible_sans_auth(self):
        response = self.client.get(f'/api/biographies/{self.bio.id}/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['titre'], 'Biographie Test')

    def test_creation_sans_auth_interdit(self):
        response = self.client.post('/api/biographies/', {'titre': 'X', 'contenu': 'Y'})
        self.assertIn(response.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])

    def test_admin_peut_creer(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.post('/api/biographies/', {'titre': 'Nouvelle', 'contenu': 'Contenu'})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_admin_peut_modifier(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.patch(f'/api/biographies/{self.bio.id}/', {'titre': 'Modifié'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['titre'], 'Modifié')

    def test_admin_peut_supprimer(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.delete(f'/api/biographies/{self.bio.id}/')
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
