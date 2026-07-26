import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../l10n/localized_text.dart';

class SchuppenschatzRulesScreen extends StatelessWidget {
  const SchuppenschatzRulesScreen({super.key});

  static const sections = <(String, String, IconData)>[
    (
      'Spielidee',
      'Zähmt Drachen, sammelt Gold – und entscheidet klug, wann ihr aufhört. '
          'Wer zu gierig würfelt, verliert alles. '
          'Nach der letzten Karte gewinnt, wer das meiste Gold besitzt.',
      Icons.emoji_events_outlined,
    ),
    (
      'Spielmaterial & Vorbereitung',
      '41 Drachenkarten, 48 Goldplättchen (1er, 5er, 20er), 5 Würfel, 1 Bonuskarte (20 Gold). '
          'Mischt die Drachenkarten und legt sie als verdeckten Stapel bereit. '
          'Für eine lange Runde spielt ihr mit allen 41 Karten, '
          'für eine schnelle Runde nur mit 20. '
          'Die Bonuskarte kommt erstmal zur Seite. Gold und Würfel bereitlegen.',
      Icons.deck_outlined,
    ),
    (
      'Die Felder auf der Karte',
      'Zahlenfeld: braucht denselben Würfelwert oder eine Flamme (6).\n'
          'Flammenfeld: nimmt ausschließlich eine gewürfelte Flamme (6) an.\n'
          'Leeres Feld: kann mit jedem beliebigen Würfelergebnis belegt werden.\n'
          'Die Flamme bringt immer 0 Gold – auch wenn sie auf einem Zahlenfeld liegt.',
      Icons.grid_view_rounded,
    ),
    (
      'Dein Zug',
      '1. Decke die oberste Drachenkarte auf.\n'
          '2. Würfle mit allen 5 Würfeln.\n'
          '3. Lege mindestens einen passenden Würfel auf die Karte.\n'
          '4. Entscheide: Weiterwürfeln oder Zug beenden?\n\n'
          'Weiterwürfeln: Wirf die übrigen Würfel erneut. Wieder muss mindestens einer passen. '
          'Passt kein einziger Würfel, ist dein Zug sofort erfolglos beendet – '
          'du bekommst kein Gold und die nächste Person ist dran.\n\n'
          'Zug beenden: Du sicherst so viel Gold, wie die Summe der bereits gelegten Würfelaugen beträgt. '
          'Die Flamme zählt dabei 0.',
      Icons.casino_outlined,
    ),
    (
      'Drachen weitergeben & zähmen',
      'Wurde ein Drache nicht gezähmt (freiwillig beendet oder Fehlversuch): '
          'Alle Würfel werden heruntergenommen und die Karte wandert zur nächsten Person, '
          'die neu würfeln darf. Zusätzlich wird ein 5er-Goldplättchen aus der Mitte auf die Karte gelegt. '
          'Für jede weitere Person, die den Drachen weitergibt, kommt ein weiteres 5er-Plättchen dazu – '
          'der Anreiz wächst also mit jeder Weitergabe.\n\n'
          'Hatten alle Personen einen Versuch und niemand hat den Drachen gezähmt, '
          'entkommt er und die Karte wird beiseitegelegt.\n\n'
          'Drachen zähmen: Sobald alle Felder mit passenden Würfeln bedeckt sind, '
          'hast du den Drachen gezähmt. Du erhältst:\n'
          '• die Summe der Würfelaugen auf der Karte\n'
          '• alle 5er-Goldplättchen, die auf der Karte liegen\n'
          '• die Drachenkarte selbst (verdeckt vor dir ablegen)',
      Icons.swap_horiz,
    ),
    (
      'Die drei Drachenarten',
      'Wasserdrache (blau): Folgt den normalen Regeln – keine Sonderbedingungen.\n\n'
          'Feuerdrache (rot): Immun gegen Flammen. Eine 6 darf hier nie auf ein Feld gelegt werden – '
          'weder auf Zahlen- noch auf Flammenfelder.\n\n'
          'Glücksdrache (gelb): Du musst so lange weiterwürfeln, '
          'bis mindestens alle gelb markierten Pflichtfelder bedeckt sind – '
          'oder dein Zug erfolglos endet. '
          'Sind alle gelben Felder gefüllt, gelten die üblichen Regeln: '
          'Du darfst freiwillig aufhören oder weiterwürfeln.',
      Icons.auto_awesome,
    ),
    (
      'Spielende & Sieg',
      'Das Spiel endet, sobald alle Drachenkarten abgehandelt sind '
          '(gezähmt oder entkommen).\n\n'
          'Die Person mit den meisten gezähmten Drachen erhält die Bonuskarte im Wert von 20 Gold. '
          'Bei Gleichstand entfällt die Bonuskarte.\n\n'
          'Nun zählt jede Person ihr gesamtes Gold zusammen. '
          'Wer das meiste Gold hat, gewinnt und wird Drachenmeister:in!',
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
                'Eigenständige Würfelblock-Adaption für 2 bis 4 Personen. '
                'Im Digitalmodus würfelt die App; im Blockmodus nutzt ihr fünf echte Würfel.',
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
