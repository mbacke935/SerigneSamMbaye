import datetime
from django.test import TestCase
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from apps.users.models import User
from .models import Citation


class CitationModelTest(TestCase):
    """Phase 2 — Modèle Citation."""

    def test_str_court(self):
        texte = 'A' * 100
        citation = Citation(texte=texte)
        self.assertEqual(len(str(citation)), 80)
        self.assertTrue(str(citation).endswith('A'))

    def test_str_texte_court(self):
        citation = Citation(texte='Courte citation')
        self.assertEqual(str(citation), 'Courte citation')

    def test_creation(self):
        citation = Citation.objects.create(
            texte='La connaissance est une lumière.',
            date_publication=datetime.date.today(),
            is_published=True,
        )
        self.assertTrue(citation.is_published)


class CitationAPITest(APITestCase):
    """Phase 5 — API /api/citations/"""

    def setUp(self):
        self.admin = User.objects.create_superuser(
            username='admin', email='admin@test.com', password='pass'
        )
        self.today = datetime.date.today()
        self.publiee = Citation.objects.create(
            texte='Citation publiée',
            date_publication=self.today,
            is_published=True,
        )
        self.non_publiee = Citation.objects.create(
            texte='Citation non publiée',
            date_publication=self.today,
            is_published=False,
        )

    def test_liste_accessible_sans_auth(self):
        response = self.client.get('/api/citations/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_public_voit_seulement_publiees(self):
        response = self.client.get('/api/citations/')
        textes = [c['texte'] for c in response.data['results']]
        self.assertIn('Citation publiée', textes)
        self.assertNotIn('Citation non publiée', textes)

    def test_admin_voit_tout(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/citations/')
        self.assertEqual(response.data['count'], 2)

    def test_citation_du_jour(self):
        response = self.client.get('/api/citations/du-jour/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['texte'], 'Citation publiée')

    def test_citation_du_jour_sans_donnees(self):
        Citation.objects.all().delete()
        response = self.client.get('/api/citations/du-jour/')
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_creation_sans_auth_interdit(self):
        response = self.client.post('/api/citations/', {})
        self.assertIn(response.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])

    def test_admin_peut_creer(self):
        self.client.force_authenticate(user=self.admin)
        data = {'texte': 'Nouvelle citation', 'date_publication': str(self.today), 'is_published': True}
        response = self.client.post('/api/citations/', data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
