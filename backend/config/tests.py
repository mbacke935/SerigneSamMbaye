from django.conf import settings
from django.contrib import admin
from django.test import TestCase
from django.urls import reverse

from apps.audios.models import Audio
from apps.biographies.models import Biographie
from apps.citations.models import Citation
from apps.favorites.models import Favori
from apps.users.models import User
from apps.videos.models import Video


class Phase1SettingsTest(TestCase):
    """Phase 1 — Vérification de la configuration initiale."""

    def test_django_rest_framework_installe(self):
        self.assertIn('rest_framework', settings.INSTALLED_APPS)

    def test_jwt_configure(self):
        self.assertIn('rest_framework_simplejwt', settings.INSTALLED_APPS)
        auth_classes = settings.REST_FRAMEWORK['DEFAULT_AUTHENTICATION_CLASSES']
        self.assertTrue(any('JWTAuthentication' in c for c in auth_classes))

    def test_cors_configure(self):
        self.assertIn('corsheaders', settings.INSTALLED_APPS)
        self.assertTrue(hasattr(settings, 'CORS_ALLOWED_ORIGINS'))
        self.assertTrue(settings.CORS_ALLOW_CREDENTIALS)

    def test_simple_jwt_durees(self):
        from datetime import timedelta
        self.assertEqual(settings.SIMPLE_JWT['ACCESS_TOKEN_LIFETIME'], timedelta(minutes=60))
        self.assertEqual(settings.SIMPLE_JWT['REFRESH_TOKEN_LIFETIME'], timedelta(days=7))

    def test_langue_fuseau_horaire(self):
        self.assertEqual(settings.LANGUAGE_CODE, 'fr-fr')
        self.assertEqual(settings.TIME_ZONE, 'Africa/Dakar')

    def test_auth_user_model(self):
        self.assertEqual(settings.AUTH_USER_MODEL, 'users.User')

    def test_pagination_configuree(self):
        self.assertEqual(settings.REST_FRAMEWORK['DEFAULT_PAGINATION_CLASS'],
                         'rest_framework.pagination.PageNumberPagination')
        self.assertEqual(settings.REST_FRAMEWORK['PAGE_SIZE'], 20)


class Phase3AdminTest(TestCase):
    """Phase 3 — Vérification de l'interface d'administration."""

    def test_url_admin_non_standard(self):
        url = reverse('admin:index')
        self.assertEqual(url, '/gestion/')
        self.assertNotEqual(url, '/admin/')

    def test_tous_les_modeles_enregistres(self):
        for model in [Audio, Video, Biographie, Citation, Favori, User]:
            with self.subTest(model=model.__name__):
                self.assertIn(model, admin.site._registry,
                              msg=f"{model.__name__} n'est pas enregistré dans l'admin")

    def test_titre_admin_personnalise(self):
        self.assertEqual(admin.site.site_header, 'Serigne Sam Mbaye — Administration')

    def test_acces_admin_sans_auth_redirige(self):
        response = self.client.get('/gestion/')
        self.assertEqual(response.status_code, 302)


class Phase4StorageTest(TestCase):
    """Phase 4 — Vérification de la configuration Cloudflare R2."""

    def test_flag_use_r2_existe(self):
        self.assertTrue(hasattr(settings, 'USE_R2'))

    def test_storages_installe(self):
        self.assertIn('storages', settings.INSTALLED_APPS)

    def test_variables_r2_dans_env(self):
        from decouple import config
        # Les variables doivent être définies dans .env (même si USE_R2=False en test)
        self.assertIsNotNone(config('R2_ACCOUNT_ID', default=None))
        self.assertIsNotNone(config('R2_BUCKET_NAME', default=None))
