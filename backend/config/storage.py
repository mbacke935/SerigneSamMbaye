from storages.backends.s3boto3 import S3Boto3Storage


def video_storage():
    """Stockage du champ vidéo, choisi à l'exécution.

    - Si `USE_CLOUDINARY` est activé : les vidéos sont envoyées sur Cloudinary,
      qui les compresse/optimise automatiquement (et soulage R2).
    - Sinon : stockage par défaut (R2 en production, système de fichiers en test).

    Passer un callable comme `storage=` permet de basculer sans toucher au modèle
    ni régénérer de migration.
    """
    from django.conf import settings

    if getattr(settings, 'USE_CLOUDINARY', False):
        from cloudinary_storage.storage import VideoMediaCloudinaryStorage
        return VideoMediaCloudinaryStorage()

    from django.core.files.storage import default_storage
    return default_storage


class R2MediaStorage(S3Boto3Storage):
    """Stockage des fichiers médias sur Cloudflare R2."""
    location = 'media'
    file_overwrite = False
    default_acl = None  # R2 gère les permissions au niveau du bucket


class R2AudioStorage(R2MediaStorage):
    location = 'media/audios'


class R2VideoStorage(R2MediaStorage):
    location = 'media/videos'


class R2ImageStorage(R2MediaStorage):
    location = 'media/images'
