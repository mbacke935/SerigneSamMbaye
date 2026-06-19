import tempfile
from config.settings import *

# Base de données SQLite en mémoire — rapide et sans dépendance réseau
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': ':memory:',
    }
}

# Stockage local — pas d'appels Cloudflare R2 pendant les tests.
# config.settings a déjà fixé STORAGES['default'] sur R2 (USE_R2=True en .env local),
# il faut donc explicitement le réinitialiser ici, sinon les tests taperaient sur R2.
USE_R2 = False
STORAGES = {
    'default': {'BACKEND': 'django.core.files.storage.FileSystemStorage'},
    'staticfiles': {'BACKEND': 'django.contrib.staticfiles.storage.StaticFilesStorage'},
}
MEDIA_ROOT = tempfile.mkdtemp()

# Désactiver le hachage de mots de passe lent en tests
PASSWORD_HASHERS = ['django.contrib.auth.hashers.MD5PasswordHasher']

# Activer la compression audio en tests pour valider la fonctionnalité
# (en production elle reste désactivée par défaut — trop lourde pour Render gratuit).
COMPRESS_AUDIO = True
