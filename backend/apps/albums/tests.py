from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from apps.audios.models import Audio
from apps.users.models import User
from .models import Album


class AlbumAPITest(APITestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser(
            username='admin', email='admin@test.com', password='pass'
        )
        self.album = Album.objects.create(titre='Khassidas', is_published=True)
        self.album_cache = Album.objects.create(titre='Brouillon', is_published=False)
        Audio.objects.create(
            titre='Audio dans album',
            fichier='audios/a.mp3',
            album=self.album,
            date_publication=timezone.now(),
            is_published=True,
        )

    def test_liste_publique_sans_auth(self):
        response = self.client.get('/api/albums/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_public_ne_voit_pas_albums_non_publies(self):
        response = self.client.get('/api/albums/')
        titres = [a['titre'] for a in response.data['results']]
        self.assertIn('Khassidas', titres)
        self.assertNotIn('Brouillon', titres)

    def test_compte_audios_publies(self):
        response = self.client.get('/api/albums/')
        album = next(a for a in response.data['results'] if a['titre'] == 'Khassidas')
        self.assertEqual(album['nb_audios'], 1)

    def test_detail_inclut_les_audios(self):
        response = self.client.get(f'/api/albums/{self.album.id}/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['audios']), 1)
        self.assertEqual(response.data['audios'][0]['titre'], 'Audio dans album')

    def test_creation_sans_auth_interdit(self):
        response = self.client.post('/api/albums/', {'titre': 'X'})
        self.assertIn(response.status_code,
                      [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])

    def test_admin_peut_creer(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.post('/api/albums/', {'titre': 'Nouvel album'})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
