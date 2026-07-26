import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../l10n/localized_text.dart';

class SchuppenschatzRulesScreen extends StatelessWidget {
  const SchuppenschatzRulesScreen({super.key});

  static const sections = <(String, String, IconData)>[
    (
      'Ziel',
      'Zähmt Drachen, sammelt Gold und entscheidet klug, wann ihr aufhört. Nach der letzten Karte gewinnt, wer insgesamt das meiste Gold besitzt.',
      Icons.emoji_events_outlined,
    ),
    (
      'Die Felder',
      'Eine Zahl braucht denselben Würfelwert. Die 6 gilt als Flamme: Sie ersetzt Zahlen, bringt aber kein Gold. Ein Flammenfeld nimmt nur eine 6, ein freies Feld jeden Wert.',
      Icons.grid_view_rounded,
    ),
    (
      'Dein Zug',
      'Würfle mit allen verfügbaren Würfeln und lege mindestens einen passenden Würfel ab. Danach würfelst du mit dem Rest weiter oder sicherst das Gold der bereits gelegten Würfel. Passt kein Würfel, endet dein Versuch sofort.',
      Icons.casino_outlined,
    ),
    (
      'Drachenarten',
      'Wasserdrachen folgen den normalen Regeln. Feuerdrachen sind gegen Flammen immun und nehmen keine 6. Bei Glücksdrachen musst du alle markierten Pflichtfelder füllen, bevor du freiwillig aufhören darfst.',
      Icons.auto_awesome,
    ),
    (
      'Gold & Spielende',
      'Ein weitergereichter Drache erhält 5 Gold. Wer ihn vollständig zähmt, gewinnt Würfelgold, Kartengold und die Karte. Nach einem Fehlversuch jeder Person entkommt er. Die alleinige Person mit den meisten Drachen erhält 20 Bonusgold; bei Gleichstand entfällt der Bonus.',
      Icons.monetization_on_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const LocalizedText('Schuppenschatz · Regeln')),
    body: SelectionArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const Card(
            color: Color(0xFFFFE7B3),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: LocalizedText(
                'Eigenständige Würfelblock-Adaption für 2 bis 4 Personen. Im Digitalmodus würfelt die App; im Blockmodus nutzt ihr fünf echte Würfel.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final section in sections)
            Card(
              semanticContainer: false,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.lavender,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(section.$3, color: AppColors.plum),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: LocalizedText(
                              section.$1,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(height: 4),
                          LocalizedText(section.$2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
