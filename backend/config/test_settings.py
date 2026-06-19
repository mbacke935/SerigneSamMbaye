import tempfile
from config.settings import *

# Base de données SQLite en mémoire — rapide et sans dépendance réseau
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': ':memory:',
    }
}

# Stockage local — pas d'appels Cloudflare R2 pendant les tests
USE_R2 = False
MEDIA_ROOT = tempfile.mkdtemp()

# Désactiver le hachage de mots de passe lent en tests
PASSWORD_HASHERS = ['django.contrib.auth.hashers.MD5PasswordHasher']
