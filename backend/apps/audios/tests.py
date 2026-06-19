import os
import subprocess
import tempfile

import imageio_ffmpeg
from django.core.files.uploadedfile import SimpleUploadedFile
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


class AudioCompressionTest(TestCase):
    """Compression automatique de l'audio à l'upload."""

    @staticmethod
    def _generer_mp3(bitrate='256k', duree=20):
        ff = imageio_ffmpeg.get_ffmpeg_exe()
        tmp = tempfile.NamedTemporaryFile(suffix='.mp3', delete=False)
        tmp.close()
        subprocess.run(
            [ff, '-y', '-f', 'lavfi', '-i', f'sine=frequency=440:duration={duree}',
             '-ac', '2', '-b:a', bitrate, tmp.name],
            check=True, capture_output=True,
        )
        with open(tmp.name, 'rb') as f:
            data = f.read()
        os.remove(tmp.name)
        return data

    def test_audio_compresse_a_lupload(self):
        brut = self._generer_mp3('256k')
        upload = SimpleUploadedFile('conference.mp3', brut, content_type='audio/mpeg')
        audio = Audio.objects.create(
            titre='Conférence',
            fichier=upload,
            date_publication=timezone.now(),
            is_published=True,
        )
        audio.refresh_from_db()
        # Le fichier stocké doit être nettement plus petit que l'original 256k stéréo.
        self.assertLess(audio.fichier.size, len(brut))
        self.assertTrue(audio.fichier.name.endswith('.mp3'))

    def test_modification_titre_ne_recompresse_pas(self):
        brut = self._generer_mp3('256k')
        upload = SimpleUploadedFile('cours.mp3', brut, content_type='audio/mpeg')
        audio = Audio.objects.create(
            titre='Cours',
            fichier=upload,
            date_publication=timezone.now(),
        )
        nom_apres_upload = audio.fichier.name
        taille_apres_upload = audio.fichier.size

        # Une simple édition de titre ne doit ni recompresser ni changer le fichier.
        audio.titre = 'Cours (corrigé)'
        audio.save()
        audio.refresh_from_db()
        self.assertEqual(audio.fichier.name, nom_apres_upload)
        self.assertEqual(audio.fichier.size, taille_apres_upload)
