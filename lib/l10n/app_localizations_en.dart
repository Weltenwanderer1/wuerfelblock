// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Würfelblock';

  @override
  String get newGame => 'New game';

  @override
  String get aboutTitle => 'About Würfelblock';

  @override
  String get privacySummary =>
      'No accounts, advertising, analytics, tracking, or network access.';

  @override
  String get language => 'Language';

  @override
  String get german => 'German';

  @override
  String get english => 'English';

  @override
  String get settingsAndInfo => 'Settings & info';

  @override
  String get manufacturer => 'Developer';

  @override
  String get manufacturerName => 'Günther Schuch';

  @override
  String get versionInformation =>
      'Würfelblock is distributed as a signed Android app.';

  @override
  String get privacyTitle => 'Privacy & offline use';

  @override
  String get privacySummaryLong =>
      'Würfelblock works completely offline. There are no accounts, advertising, analytics, tracking, or network access.';

  @override
  String get localData =>
      'Game states, entered names, and the language choice stay only on this device. Android cloud backup and device transfer are disabled.';

  @override
  String get deleteData =>
      'You can remove this local data by deleting an active game or uninstalling the app.';

  @override
  String get developerNoAccess =>
      'The developer cannot access names, game states, or any other local app data. No data is transmitted to third parties.';

  @override
  String get languageSaveFailed => 'The language choice could not be saved.';
}
