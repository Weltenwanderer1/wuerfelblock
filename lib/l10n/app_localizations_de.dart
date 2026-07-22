// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Würfelblock';

  @override
  String get newGame => 'Neue Partie';

  @override
  String get aboutTitle => 'Über Würfelblock';

  @override
  String get privacySummary =>
      'Keine Konten, Werbung, Analyse, Tracking oder Netzwerkzugriffe.';

  @override
  String get language => 'Sprache';

  @override
  String get german => 'Deutsch';

  @override
  String get english => 'Englisch';

  @override
  String get settingsAndInfo => 'Einstellungen & Info';

  @override
  String get manufacturer => 'Entwickelt von';

  @override
  String get manufacturerName => 'Günther Schuch';

  @override
  String get versionInformation =>
      'Würfelblock wird als signierte Android-App veröffentlicht.';

  @override
  String get privacyTitle => 'Datenschutz & Offline-Nutzung';

  @override
  String get privacySummaryLong =>
      'Würfelblock funktioniert vollständig offline. Es gibt keine Konten, Werbung, Analyse, Tracking oder Netzwerkzugriffe.';

  @override
  String get localData =>
      'Spielstände, eingegebene Namen und die Sprachwahl bleiben ausschließlich lokal auf diesem Gerät. Android-Cloud-Backup und Geräteübertragung sind deaktiviert.';

  @override
  String get deleteData =>
      'Diese lokalen Daten können durch das Löschen einer laufenden Partie oder durch Deinstallieren der App entfernt werden.';

  @override
  String get developerNoAccess =>
      'Der Entwickler hat keinen Zugriff auf Namen, Spielstände oder andere lokale App-Daten. Es werden keine Daten an Dritte übermittelt.';

  @override
  String get languageSaveFailed =>
      'Die Sprachwahl konnte nicht gespeichert werden.';
}
