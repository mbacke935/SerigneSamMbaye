"""Auto-génération de miniatures pour les vidéos sans image_miniature.

Deux stratégies :
  - YouTube : URL de thumbnail officielle (pas de téléchargement vidéo).
  - Fichier direct : FFmpeg (via imageio-ffmpeg) extrait une frame à 5 s.
"""
import logging
import os
import re
import subprocess
import tempfile

from django.core.files.base import ContentFile

logger = logging.getLogger(__name__)

_YT_RE = re.compile(
    r'(?:youtube\.com/(?:watch\?.*v=|embed/|shorts/)|youtu\.be/)([A-Za-z0-9_-]{11})'
)


def extract_youtube_id(url: str) -> str | None:
    if not url:
        return None
    m = _YT_RE.search(url)
    return m.group(1) if m else None


def youtube_thumbnail_url(url: str) -> str | None:
    """Retourne l'URL publique de la miniature YouTube, ou None si non-YouTube."""
    vid = extract_youtube_id(url)
    return f'https://img.youtube.com/vi/{vid}/mqdefault.jpg' if vid else None


def _ffmpeg_exe() -> str:
    import imageio_ffmpeg
    return imageio_ffmpeg.get_ffmpeg_exe()


def extract_frame_from_file(filefield, at_seconds: float = 5.0) -> ContentFile | None:
    """Extrait une frame JPEG d'un fichier vidéo uploadé.

    `filefield` doit être un UploadedFile (non encore commis au stockage).
    """
    in_path = out_path = None
    try:
        src = filefield.file
        src.seek(0)
        suffix = os.path.splitext(filefield.name)[1] or '.mp4'
        with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
            for chunk in src.chunks():
                tmp.write(chunk)
            in_path = tmp.name

        out_path = in_path + '.thumb.jpg'
        subprocess.run(
            [_ffmpeg_exe(), '-y', '-ss', str(at_seconds),
             '-i', in_path, '-frames:v', '1', '-q:v', '2', out_path],
            check=True, capture_output=True, timeout=30,
        )
        if os.path.exists(out_path) and os.path.getsize(out_path) > 0:
            with open(out_path, 'rb') as f:
                return ContentFile(f.read(), name='thumbnail.jpg')
    except Exception as exc:
        logger.warning('extract_frame_from_file: %s', exc)
    finally:
        for p in (in_path, out_path):
            if p and os.path.exists(p):
                try:
                    os.remove(p)
                except OSError:
                    pass
    return None


def extract_frame_from_url(url: str, at_seconds: float = 5.0) -> ContentFile | None:
    """Extrait une frame JPEG d'une URL vidéo directe via FFmpeg.

    FFmpeg fait une requête HTTP range pour ne télécharger que les premières
    secondes — efficace pour les MP4 d'Archive.org.
    Timeout : 60 s pour laisser le temps à une connexion lente.
    """
    out_path = None
    try:
        with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as tmp:
            out_path = tmp.name
        subprocess.run(
            [_ffmpeg_exe(), '-y', '-ss', str(at_seconds),
             '-i', url, '-frames:v', '1', '-q:v', '2', out_path],
            check=True, capture_output=True, timeout=60,
        )
        if os.path.exists(out_path) and os.path.getsize(out_path) > 0:
            with open(out_path, 'rb') as f:
                return ContentFile(f.read(), name='thumbnail.jpg')
    except Exception as exc:
        logger.warning('extract_frame_from_url %s : %s', url[:60], exc)
    finally:
        if out_path and os.path.exists(out_path):
            try:
                os.remove(out_path)
            except OSError:
                pass
    return None
