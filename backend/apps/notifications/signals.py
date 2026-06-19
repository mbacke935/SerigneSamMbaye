from django.db.models.signals import pre_save, post_save
from django.dispatch import receiver

from apps.audios.models import Audio
from apps.citations.models import Citation
from apps.videos.models import Video

from .utils import send_topic_notification


def _store_was_published(sender, instance, **kwargs):
    """Cache previous is_published value on the instance before saving."""
    if instance.pk:
        prev = sender.objects.filter(pk=instance.pk).values_list('is_published', flat=True).first()
        instance._was_published = bool(prev)
    else:
        instance._was_published = False


# ── Audio ──────────────────────────────────────────────────────────────────

@receiver(pre_save, sender=Audio)
def audio_pre_save(sender, instance, **kwargs):
    _store_was_published(sender, instance, **kwargs)


@receiver(post_save, sender=Audio)
def audio_post_save(sender, instance, created, **kwargs):
    if instance.is_published and not getattr(instance, '_was_published', False):
        send_topic_notification(
            topic='audio',
            title='Nouvel audio disponible',
            body=instance.titre,
            data={'type': 'audio', 'id': instance.pk},
        )


# ── Video ──────────────────────────────────────────────────────────────────

@receiver(pre_save, sender=Video)
def video_pre_save(sender, instance, **kwargs):
    _store_was_published(sender, instance, **kwargs)


@receiver(post_save, sender=Video)
def video_post_save(sender, instance, created, **kwargs):
    if instance.is_published and not getattr(instance, '_was_published', False):
        send_topic_notification(
            topic='video',
            title='Nouvelle vidéo disponible',
            body=instance.titre,
            data={'type': 'video', 'id': instance.pk},
        )


# ── Citation ───────────────────────────────────────────────────────────────

@receiver(pre_save, sender=Citation)
def citation_pre_save(sender, instance, **kwargs):
    _store_was_published(sender, instance, **kwargs)


@receiver(post_save, sender=Citation)
def citation_post_save(sender, instance, created, **kwargs):
    if instance.is_published and not getattr(instance, '_was_published', False):
        texte = instance.texte[:80] + '…' if len(instance.texte) > 80 else instance.texte
        send_topic_notification(
            topic='citation',
            title='Nouvelle citation',
            body=texte,
            data={'type': 'citation', 'id': instance.pk},
        )
