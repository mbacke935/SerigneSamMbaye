"""Compression média côté serveur.

L'audio est ré-encodé à l'upload vers un MP3 mono basse débit (voix), ce qui
réduit fortement la taille stockée sur R2 sans infrastructure supplémentaire.
Le binaire ffmpeg est fourni par le paquet pip `imageio-ffmpeg` (aucune
installation système requise — important sur Render).

La compression vidéo n'est volontairement PAS faite ici : trop lourde pour
l'instance Render gratuite (RAM 512 Mo, timeout Gunicorn). Elle est déléguée à
Cloudinary (voir le stockage du modèle Video).
"""
import logging
import os
import subprocess
import tempfile
from urllib.parse import quote, urlsplit, urlunsplit

from django.core.files.base import ContentFile
from django.core.files.uploadedfile import UploadedFile

logger = logging.getLogger(__name__)


def normalize_external_url(url: str) -> str:
    """Encode les caractères non sûrs d'une URL externe (espaces, accents).

    Les noms de fichiers Internet Archive contiennent souvent des espaces ou des
    accents (ex. `s.sam 56.mp3`, `Léçon n°2.mp3`). Stockés bruts dans
    `lien_externe`, ils empêchent les lecteurs (mobile/web) de charger le média.

    On encode le chemin et la requête tout en gardant `%` « sûr » : un `%20`
    déjà présent n'est donc pas ré-encodé en `%2520`. Idempotent.
    """
    url = (url or '').strip()
    if not url:
        return url
    try:
        parts = urlsplit(url)
        if not parts.scheme or not parts.netloc:
            return url  # pas une URL absolue : on n'y touche pas
        path = quote(parts.path, safe="/%:@-._~!$&'()*+,;=")
        query = quote(parts.query, safe="/%:@-._~!$&'()*+,;=?")
        return urlunsplit((parts.scheme, parts.netloc, path, query, parts.fragment))
    except Exception:
        return url

# Débit cible pour la voix : 64 kbit/s mono est largement suffisant pour des
# enregistrements parlés et divise la taille par ~3 à 4 par rapport à du stéréo 256k.
AUDIO_BITRATE = '64k'
# Garde-fou : au-delà de cette taille on saute la compression synchrone pour ne
# pas risquer un timeout / OOM (même quand COMPRESS_AUDIO est activé).
MAX_INPUT_BYTES = 30 * 1024 * 1024  # 30 Mo


def is_new_upload(filefield) -> bool:
    """Vrai uniquement si le champ porte un fichier fraîchement téléversé
    (et non un fichier déjà présent dans le stockage).

    On s'appuie sur `_committed` (False tant que le fichier n'est pas écrit dans
    le stockage) — le même signal qu'utilise Django dans `FileField.pre_save`.
    Cela évite d'ouvrir inutilement le stockage distant (R2) pour un fichier déjà
    persistant.
    """
    if not filefield:
        return False
    if getattr(filefield, '_committed', True):
        return False
    return isinstance(getattr(filefield, 'file', None), UploadedFile)


def _ffmpeg_exe() -> str:
    import imageio_ffmpeg
    return imageio_ffmpeg.get_ffmpeg_exe()


def compress_audio(filefield, bitrate: str = AUDIO_BITRATE):
    """Ré-encode un fichier audio téléversé en MP3 mono basse débit.

    Renvoie un `ContentFile` prêt à être assigné au champ, ou `None` si la
    compression échoue ou n'apporte aucun gain (on garde alors l'original).
    """
    try:
        if filefield.size and filefield.size > MAX_INPUT_BYTES:
            logger.info('Audio trop volumineux (%s o), compression ignorée.', filefield.size)
            return None
    except Exception:
        pass

    suffix = os.path.splitext(filefield.name)[1] or '.mp3'
    in_path = out_path = None
    try:
        src = filefield.file
        src.seek(0)
        with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp_in:
            for chunk in src.chunks():
                tmp_in.write(chunk)
            in_path = tmp_in.name
        out_path = in_path + '.compressed.mp3'

        subprocess.run(
            [_ffmpeg_exe(), '-y', '-i', in_path,
             '-ac', '1', '-b:a', bitrate, '-vn', out_path],
            check=True, capture_output=True, timeout=120,
        )

        original_size = os.path.getsize(in_path)
        new_size = os.path.getsize(out_path)
        if new_size == 0 or new_size >= original_size:
            return None

        with open(out_path, 'rb') as f:
            data = f.read()
        base = os.path.splitext(os.path.basename(filefield.name))[0]
        logger.info('Audio compressé : %s o -> %s o', original_size, new_size)
        return ContentFile(data, name=f'{base}.mp3')
    except Exception as exc:
        logger.warning('Compression audio échouée, fichier original conservé : %s', exc)
        return None
    finally:
        for p in (in_path, out_path):
            if p and os.path.exists(p):
                try:
                    os.remove(p)
                except OSError:
                    pass
