import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

const _topics = ['audio', 'video', 'citation'];
const _prefix = 'notif_pref_';

class NotificationPrefsService {
  static final NotificationPrefsService _instance =
      NotificationPrefsService._();
  factory NotificationPrefsService() => _instance;
  NotificationPrefsService._();

  Future<Map<String, bool>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final t in _topics) t: prefs.getBool('$_prefix$t') ?? true,
    };
  }

  Future<bool> isEnabled(String topic) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$topic') ?? true;
  }

  Future<void> setEnabled(String topic, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$topic', value);
    if (!kIsWeb) {
      if (value) {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      }
    }
  }

  Future<void> applyAll() async {
    if (kIsWeb) return;
    final all = await loadAll();
    for (final entry in all.entries) {
      if (entry.value) {
        await FirebaseMessaging.instance.subscribeToTopic(entry.key);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(entry.key);
      }
    }
  }
}
