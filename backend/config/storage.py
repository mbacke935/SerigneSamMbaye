from storages.backends.s3boto3 import S3Boto3Storage


def _media_storage_for(media_kind: str):
    """Choisit le stockage à l'exécution selon `USE_CLOUDINARY`.

    - Activé : Cloudinary, qui compresse/optimise automatiquement (et soulage R2).
      L'audio comme la vidéo passent par le resource_type « video » de Cloudinary
      (Cloudinary gère l'audio sous ce type).
    - Désactivé : stockage par défaut (R2 en prod, système de fichiers en test).
    """
    from django.conf import settings

    if getattr(settings, 'USE_CLOUDINARY', False):
        from cloudinary_storage.storage import VideoMediaCloudinaryStorage
        return VideoMediaCloudinaryStorage()

    from django.core.files.storage import default_storage
    return default_storage


def video_storage():
    """Stockage du champ vidéo (Cloudinary si activé, sinon R2)."""
    return _media_storage_for('video')


def audio_storage():
    """Stockage du champ audio (Cloudinary si activé, sinon R2)."""
    return _media_storage_for('audio')


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
