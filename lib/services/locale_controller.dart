import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  LocaleController(SharedPreferences preferences)
    : _preferences = preferences,
      locale = _fromStoredCode(preferences.getString(preferenceKey));

  LocaleController.ephemeral()
    : _preferences = null,
      locale = const Locale('de');

  static const preferenceKey = 'app_locale_v1';
  static const supportedLanguageCodes = {'de', 'en'};

  static Locale? _fromStoredCode(String? code) {
    if (code == null) return null;
    if (supportedLanguageCodes.contains(code)) return Locale(code);
    return const Locale('de');
  }

  final SharedPreferences? _preferences;
  Locale? locale;

  Future<void> select(Locale selected) async {
    if (!supportedLanguageCodes.contains(selected.languageCode)) return;
    final stored =
        await _preferences?.setString(preferenceKey, selected.languageCode) ??
        true;
    if (!stored) throw StateError('Language selection could not be saved.');
    locale = Locale(selected.languageCode);
    notifyListeners();
  }
}
