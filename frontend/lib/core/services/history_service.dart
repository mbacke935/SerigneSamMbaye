import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audio_model.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  static const _key = 'listen_history';
  static const _max = 20;

  Future<void> add(AudioModel audio) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final list = raw != null
        ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    list.removeWhere((e) => e['id'] == audio.id);
    list.insert(0, audio.toJson());
    if (list.length > _max) list.removeRange(_max, list.length);
    await prefs.setString(_key, jsonEncode(list));
  }

  Future<List<AudioModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => AudioModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
