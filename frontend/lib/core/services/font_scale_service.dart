import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontScaleService extends ChangeNotifier {
  static final FontScaleService _instance = FontScaleService._();
  factory FontScaleService() => _instance;
  FontScaleService._();

  static const _key = 'font_scale';
  double _scale = 1.0;

  double get scale => _scale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _scale = prefs.getDouble(_key) ?? 1.0;
    notifyListeners();
  }

  Future<void> setScale(double value) async {
    _scale = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, value);
    notifyListeners();
  }
}
