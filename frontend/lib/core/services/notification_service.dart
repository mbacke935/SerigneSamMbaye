import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/local_notification_model.dart';

const _kTopics = ['audio', 'video', 'citation'];
const _kHistoryKey = 'notification_history';
const _kMaxHistory = 50;

/// Background handler — top-level function, mobile uniquement.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _localPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _localPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
    }

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Topics non supportés sur Web — applique les préférences sauvegardées
    if (!kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      for (final topic in _kTopics) {
        final enabled = prefs.getBool('notif_pref_$topic') ?? true;
        if (enabled) {
          await FirebaseMessaging.instance.subscribeToTopic(topic);
        }
      }
    }

    FirebaseMessaging.onMessage.listen(_onForeground);
  }

  Future<void> _onForeground(RemoteMessage message) async {
    await _save(message);

    if (!kIsWeb) {
      final notif = message.notification;
      if (notif == null) return;
      await _localPlugin.show(
        notif.hashCode,
        notif.title,
        notif.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ssm_channel',
            'Serigne Sam Mbaye',
            channelDescription: 'Nouvelles publications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  Future<void> _save(RemoteMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_kHistoryKey) ?? [];
    final model = LocalNotificationModel(
      id: message.messageId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      type: message.data['type'] as String? ?? 'tous',
      receivedAt: DateTime.now(),
    );
    history.insert(0, model.toJsonString());
    if (history.length > _kMaxHistory) {
      history.removeRange(_kMaxHistory, history.length);
    }
    await prefs.setStringList(_kHistoryKey, history);
  }

  Future<List<LocalNotificationModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kHistoryKey) ?? [];
    return raw.map(LocalNotificationModel.fromJsonString).toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistoryKey);
  }
}
