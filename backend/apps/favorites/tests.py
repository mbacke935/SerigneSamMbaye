import datetime
from django.test import TestCase
from django.contrib.contenttypes.models import ContentType
from rest_framework import status
from rest_framework.test import APITestCase

from apps.users.models import User
from apps.citations.models import Citation
from .models import Favori


class FavoriModelTest(TestCase):
    """Phase 2 — Modèle Favori."""

    def setUp(self):
        self.user = User.objects.create_user(
            username='user', email='user@test.com', password='pass'
        )
        self.citation = Citation.objects.create(
            texte='Citation test',
            date_publication=datetime.date.today(),
            is_published=True,
        )

    def test_creation_favori(self):
        ct = ContentType.objects.get_for_model(Citation)
        favori = Favori.objects.create(
            user=self.user,
            content_type=ct,
            object_id=self.citation.id,
        )
        self.assertEqual(favori.user, self.user)
        self.assertEqual(favori.content_object, self.citation)

    def test_unicite_favori(self):
        from django.db import IntegrityError
        ct = ContentType.objects.get_for_model(Citation)
        Favori.objects.create(user=self.user, content_type=ct, object_id=self.citation.id)
        with self.assertRaises(IntegrityError):
            Favori.objects.create(user=self.user, content_type=ct, object_id=self.citation.id)


class FavoriAPITest(APITestCase):
    """Phase 5 — API /api/favorites/"""

    def setUp(self):
        self.user1 = User.objects.create_user(
            username='user1', email='user1@test.com', password='pass'
        )
        self.user2 = User.objects.create_user(
            username='user2', email='user2@test.com', password='pass'
        )
        self.citation = Citation.objects.create(
            texte='Citation test',
            date_publication=datetime.date.today(),
            is_published=True,
        )
        ct = ContentType.objects.get_for_model(Citation)
        self.favori = Favori.objects.create(
            user=self.user1,
            content_type=ct,
            object_id=self.citation.id,
        )

    def test_liste_exige_authentification(self):
        response = self.client.get('/api/favorites/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_utilisateur_voit_ses_favoris(self):
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/favorites/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)

    def test_utilisateur_ne_voit_pas_favoris_des_autres(self):
        self.client.force_authenticate(user=self.user2)
        response = self.client.get('/api/favorites/')
        self.assertEqual(response.data['count'], 0)

    def test_ajout_favori(self):
        from apps.biographies.models import Biographie
        bio = Biographie.objects.create(titre='Bio', contenu='Contenu')
        ct = ContentType.objects.get_for_model(Biographie)
        self.client.force_authenticate(user=self.user1)
        data = {'content_type': ct.id, 'object_id': bio.id}
        response = self.client.post('/api/favorites/', data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_suppression_favori(self):
        self.client.force_authenticate(user=self.user1)
        response = self.client.delete(f'/api/favorites/{self.favori.id}/')
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
