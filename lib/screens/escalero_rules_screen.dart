import 'package:flutter/material.dart';

class EscaleroRulesScreen extends StatelessWidget {
  const EscaleroRulesScreen({super.key});

  static const sections = <(String, String, IconData)>[
    (
      'Ziel und Material',
      'Escalero wird mit fünf Pokerwürfeln gespielt. Ihre Bilder sind 9, 10, Bube, Dame, König und Ass. Zwei oder drei Personen füllen jeweils ein eigenes Blatt mit zehn Reihen und drei Kolonnen.',
      Icons.casino_outlined,
    ),
    (
      'Ein Zug',
      'Du darfst ein-, zwei- oder dreimal würfeln. Nach dem ersten und zweiten Wurf kannst du beliebige Würfel halten oder wieder freigeben. Spätestens nach dem dritten Wurf trägst du genau ein freies Feld ein. Ein unbrauchbarer Wurf darf mit 0 gestrichen werden.',
      Icons.touch_app_outlined,
    ),
    (
      'Bilder',
      'Gleiche Bilder zählen nach ihrer Wertigkeit: Neunen je 1 Punkt, Zehnen je 2, Buben je 3, Damen je 4, Könige je 5 und Asse je 6. Beispiel: drei Könige ergeben 15 Punkte.',
      Icons.style_outlined,
    ),
    (
      'Kombinationen',
      'Straße (9-10-B-D-K oder 10-B-D-K-A): 20 Punkte. Full House (drei gleiche plus zwei gleiche): 30. Poker (mindestens vier gleiche): 40. Grande (fünf gleiche): 50 Punkte. Fünf gleiche dürfen auch als Poker oder Full House gewertet werden.',
      Icons.auto_awesome_outlined,
    ),
    (
      'Serviert',
      'Entsteht die Kombination in einem einzigen Wurf mit allen fünf Würfeln, ist sie serviert: Straße 25, Full House 35, Poker 45 und Grande 80 Punkte. Das kann im ersten, zweiten oder dritten Wurf geschehen; beim entscheidenden Wurf darf kein Würfel gehalten sein.',
      Icons.room_service_outlined,
    ),
    (
      'Kolonnen und Abrechnung',
      'Jede Kolonne hat genau einen Sieger: die Person mit der höchsten Kolonnensumme. Die erste Kolonne zählt 1, die zweite 2 und die dritte 4 Spielpunkte. Bei drei Personen erhält der Kolonnensieger den Wert von jedem der beiden Gegner; beide Gegner verlieren diesen Wert. Ein Gleichstand an der Spitze bringt niemandem Punkte. Wer alle drei Kolonnen gewinnt, erhält zusätzlich 2 Punkte von jedem Gegner – insgesamt also 9 pro Gegner.',
      Icons.emoji_events_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF8E8),
    appBar: AppBar(title: const Text('Escalero-Regeln')),
    body: SelectionArea(
      child: ListView(
        key: const Key('escalero-rules-scroll'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Semantics(
            header: true,
            child: Text(
              'Würfelpoker mit drei Kolonnen',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF38251D),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < sections.length; index++)
            _RuleCard(
              key: Key('escalero-rule-$index'),
              title: sections[index].$1,
              text: sections[index].$2,
              icon: sections[index].$3,
            ),
          Card(
            key: const Key('escalero-rules-source'),
            semanticContainer: false,
            color: const Color(0xFFFFE8BD),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Maßgeblich ist die originale deutschsprachige Escalero-Spielanleitung. Die Piatnik-Regelbeschreibung auf Wikipedia bestätigt dieselbe Wertung.',
                style: TextStyle(height: 1.4),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.title,
    required this.text,
    required this.icon,
    super.key,
  });
  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    semanticContainer: false,
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF7C2D12)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(text, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
