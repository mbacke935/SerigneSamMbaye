import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audio_model.dart';
import 'download_file_web.dart'
    if (dart.library.io) 'download_file_native.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  static const _metaKey = 'downloads_meta';
  final Map<int, String> _localPaths = {};
  final Map<int, ValueNotifier<double>> _progress = {};

  Future<void> init() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_metaKey);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in map.entries) {
        final id = int.tryParse(e.key);
        if (id != null && fileExists(e.value as String)) {
          _localPaths[id] = e.value as String;
        }
      }
    }
  }

  Future<String> _buildPath(int audioId, String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = url.split('.').last.split('?').first;
    final safeExt = ext.length <= 4 ? ext : 'mp3';
    return '${dir.path}/audio_$audioId.$safeExt';
  }

  Future<void> _saveMeta() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _metaKey,
      jsonEncode(_localPaths.map((k, v) => MapEntry(k.toString(), v))),
    );
  }

  bool isDownloaded(int id) => _localPaths.containsKey(id);
  String? getLocalPath(int id) => _localPaths[id];

  ValueNotifier<double> progressOf(int id) =>
      _progress.putIfAbsent(id, () => ValueNotifier(0.0));

  Future<void> downloadAudio(AudioModel audio) async {
    if (kIsWeb) return;
    final url = audio.sourceUrl;
    if (url == null || url.isEmpty) return;
    final path = await _buildPath(audio.id, url);
    final notifier = progressOf(audio.id);
    notifier.value = 0.01;
    try {
      await downloadFile(url, path, (p) => notifier.value = p);
      _localPaths[audio.id] = path;
      await _saveMeta();
      notifier.value = 1.0;
    } catch (_) {
      notifier.value = 0.0;
    }
  }

  Future<void> deleteAudio(int id) async {
    if (kIsWeb) return;
    final path = _localPaths[id];
    if (path != null) {
      await deleteFile(path);
      _localPaths.remove(id);
      await _saveMeta();
    }
    _progress[id]?.value = 0.0;
    _progress.remove(id);
  }
}
