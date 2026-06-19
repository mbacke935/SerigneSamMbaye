from storages.backends.s3boto3 import S3Boto3Storage


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
