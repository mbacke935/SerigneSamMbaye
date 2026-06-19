from datetime import timedelta
from pathlib import Path

from decouple import config

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = config('SECRET_KEY')
DEBUG = config('DEBUG', default=False, cast=bool)
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost,127.0.0.1').split(',')

DJANGO_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

THIRD_PARTY_APPS = [
    'rest_framework',
    'corsheaders',
    'rest_framework_simplejwt',
    'storages',
    'drf_spectacular',
]

LOCAL_APPS = [
    'apps.users',
    'apps.albums',
    'apps.biographies',
    'apps.audios',
    'apps.videos',
    'apps.citations',
    'apps.favorites',
    'apps.notifications',
    'apps.search',
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'config.middleware.NoCacheAPIMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DB_NAME'),
        'USER': config('DB_USER'),
        'PASSWORD': config('DB_PASSWORD'),
        'HOST': config('DB_HOST', default='localhost'),
        'PORT': config('DB_PORT', default='5432'),
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'fr-fr'
TIME_ZONE = 'Africa/Dakar'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'static'

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# --- Fichiers statiques (WhiteNoise) ---
STORAGES = {
    'default': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
    'staticfiles': {
        'BACKEND': 'whitenoise.storage.CompressedManifestStaticFilesStorage',
    },
}

# --- Cloudflare R2 ---
USE_R2 = config('USE_R2', default=False, cast=bool)

if USE_R2:
    R2_ACCOUNT_ID = config('R2_ACCOUNT_ID')
    R2_PUBLIC_DOMAIN = config('R2_PUBLIC_DOMAIN', default='')

    STORAGES['default'] = {
        'BACKEND': 'config.storage.R2MediaStorage',
    }

    AWS_ACCESS_KEY_ID = config('R2_ACCESS_KEY_ID')
    AWS_SECRET_ACCESS_KEY = config('R2_SECRET_ACCESS_KEY')
    AWS_STORAGE_BUCKET_NAME = config('R2_BUCKET_NAME')
    AWS_S3_ENDPOINT_URL = f'https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com'
    AWS_S3_REGION_NAME = 'auto'
    AWS_DEFAULT_ACL = None
    AWS_S3_FILE_OVERWRITE = False
    AWS_QUERYSTRING_AUTH = False

    if R2_PUBLIC_DOMAIN:
        AWS_S3_CUSTOM_DOMAIN = R2_PUBLIC_DOMAIN
        MEDIA_URL = f'https://{R2_PUBLIC_DOMAIN}/media/'
    else:
        MEDIA_URL = f'https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com/{config("R2_BUCKET_NAME")}/media/'

# --- Cloudinary (compression vidéo, optionnel) ---
# Désactivé par défaut : tant que USE_CLOUDINARY=False, les vidéos restent sur R2.
USE_CLOUDINARY = config('USE_CLOUDINARY', default=False, cast=bool)

if USE_CLOUDINARY:
    INSTALLED_APPS += ['cloudinary', 'cloudinary_storage']
    CLOUDINARY_STORAGE = {
        'CLOUD_NAME': config('CLOUDINARY_CLOUD_NAME'),
        'API_KEY': config('CLOUDINARY_API_KEY'),
        'API_SECRET': config('CLOUDINARY_API_SECRET'),
    }

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

AUTH_USER_MODEL = 'users.User'

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': False,
    'AUTH_HEADER_TYPES': ('Bearer',),
}

CORS_ALLOW_CREDENTIALS = True
CORS_ALLOWED_ORIGINS = config('CORS_ALLOWED_ORIGINS', default='http://localhost:3000').split(',')
# Autorise le domaine canonique ET toutes les URLs de déploiement Cloudflare
# Pages (<hash>.serigne-sam-mbaye.pages.dev) générées par chaque `wrangler deploy`.
CORS_ALLOWED_ORIGIN_REGEXES = [
    r"^https://([a-z0-9-]+\.)?serigne-sam-mbaye\.pages\.dev$",
]
if DEBUG:
    # En développement local uniquement : autorise toutes les origines.
    CORS_ALLOW_ALL_ORIGINS = True

# --- Durcissement sécurité (production uniquement) ---
if not DEBUG:
    # Render termine le TLS en amont et transmet le protocole d'origine via cet en-tête.
    # Indispensable avant d'activer SECURE_SSL_REDIRECT pour éviter une boucle de redirection.
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_HSTS_SECONDS = 31536000  # 1 an
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    SECURE_CONTENT_TYPE_NOSNIFF = True

SPECTACULAR_SETTINGS = {
    'TITLE': 'Serigne Sam Mbaye API',
    'DESCRIPTION': 'API de la plateforme numérique dédiée aux enseignements de Serigne Sam Mbaye.',
    'VERSION': '1.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
}

# --- Firebase Cloud Messaging ---
# Local : chemin vers le fichier JSON
FIREBASE_CREDENTIALS_PATH = config('FIREBASE_CREDENTIALS_PATH', default='')
# Production (Render) : contenu JSON en variable d'environnement
FIREBASE_CREDENTIALS_JSON = config('FIREBASE_CREDENTIALS_JSON', default='')
