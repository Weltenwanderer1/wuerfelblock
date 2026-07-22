import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/locale_controller.dart';

class AboutPrivacyScreen extends StatelessWidget {
  const AboutPrivacyScreen({required this.localeController, super.key});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.language, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'de',
                label: Text(l10n.german, key: const Key('language-de')),
                icon: const Icon(Icons.language),
              ),
              ButtonSegment(
                value: 'en',
                label: Text(l10n.english, key: const Key('language-en')),
                icon: const Icon(Icons.language),
              ),
            ],
            selected: {selectedCode == 'en' ? 'en' : 'de'},
            onSelectionChanged: (selection) async {
              try {
                await localeController.select(Locale(selection.single));
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.languageSaveFailed)),
                );
              }
            },
          ),
          const SizedBox(height: 28),
          Text(
            l10n.manufacturer,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(l10n.manufacturerName),
          const SizedBox(height: 8),
          Text(l10n.versionInformation),
          const SizedBox(height: 28),
          Text(
            l10n.privacyTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(l10n.privacySummaryLong, key: const Key('privacy-summary')),
          const SizedBox(height: 12),
          Text(l10n.localData),
          const SizedBox(height: 12),
          Text(l10n.deleteData),
          const SizedBox(height: 12),
          Text(l10n.developerNoAccess),
        ],
      ),
    );
  }
}
