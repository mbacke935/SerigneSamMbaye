import json
import logging
from django.conf import settings

logger = logging.getLogger(__name__)


def send_topic_notification(topic: str, title: str, body: str, data: dict | None = None):
    """Send FCM notification to a topic. Silently skips if Firebase is not configured."""
    credentials_path = getattr(settings, 'FIREBASE_CREDENTIALS_PATH', '')
    credentials_json = getattr(settings, 'FIREBASE_CREDENTIALS_JSON', '')

    if not credentials_path and not credentials_json:
        return

    try:
        import firebase_admin
        from firebase_admin import credentials, messaging

        if not firebase_admin._apps:
            if credentials_path:
                cred = credentials.Certificate(credentials_path)
            else:
                cred = credentials.Certificate(json.loads(credentials_json))
            firebase_admin.initialize_app(cred)

        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            topic=topic,
        )
        messaging.send(message)
        logger.info('FCM notification sent to topic "%s": %s', topic, title)
    except Exception as exc:
        logger.warning('FCM send failed (topic=%s): %s', topic, exc)
