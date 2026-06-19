from django.test import TestCase
from .models import User


class UserModelTest(TestCase):
    """Phase 2 — Modèle User."""

    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123',
        )

    def test_username_field_est_email(self):
        self.assertEqual(User.USERNAME_FIELD, 'email')

    def test_required_fields(self):
        self.assertIn('username', User.REQUIRED_FIELDS)

    def test_str_retourne_email(self):
        self.assertEqual(str(self.user), 'test@example.com')

    def test_creation_utilisateur(self):
        self.assertEqual(self.user.email, 'test@example.com')
        self.assertTrue(self.user.check_password('testpass123'))
        self.assertFalse(self.user.is_staff)
        self.assertFalse(self.user.is_superuser)

    def test_creation_superuser(self):
        admin = User.objects.create_superuser(
            username='admin',
            email='admin@example.com',
            password='adminpass123',
        )
        self.assertTrue(admin.is_staff)
        self.assertTrue(admin.is_superuser)

    def test_email_unique(self):
        from django.db import IntegrityError
        with self.assertRaises(IntegrityError):
            User.objects.create_user(
                username='autre',
                email='test@example.com',  # même email
                password='pass',
            )
