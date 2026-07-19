import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../models/rules_content.dart';
import 'rules_widgets.dart';

class ClassicScoreSheet extends StatelessWidget {
  const ClassicScoreSheet({
    required this.state,
    required this.busy,
    required this.onEnterScore,
    super.key,
  });

  final GameState state;
  final bool busy;
  final void Function(ScoreCategory category, int playerIndex) onEnterScore;

  static const _paper = Color(0xFFFFFDF5);
  static const _ink = Color(0xFF17202A);
  static const _blue = Color(0xFF264F78);
  static const _red = Color(0xFF9E2F35);
  static const _labelWidth = 190.0;
  static const _cellWidth = 88.0;

  @override
  Widget build(BuildContext context) {
    final upper = state.ruleSet.categories.where(
      (category) => category.isUpper,
    );
    final lower = state.ruleSet.categories.where(
      (category) => !category.isUpper,
    );
    return DecoratedBox(
      key: const Key('classic-score-sheet'),
      decoration: BoxDecoration(
        color: _paper,
        border: Border.all(color: _ink, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _headerRow(),
          _sectionRow('OBERER BLOCK', _blue),
          for (final category in upper) _categoryRow(category),
          _summaryRow('Obere Summe', [
            for (final player in state.players) player.upperTotal,
          ]),
          _summaryRow('Bonus ab 63', [
            for (final player in state.players) state.bonusFor(player),
          ], accent: _red),
          _sectionRow('UNTERER BLOCK', _red),
          for (final category in lower) _categoryRow(category),
          if (state.ruleSet == RuleSet.kniffel)
            _summaryRow('Zusatz-Kniffel', [
              for (final player in state.players) player.extraKniffel * 50,
            ]),
          _summaryRow(
            'GESAMT',
            [for (final player in state.players) state.totalFor(player)],
            accent: _blue,
            inverted: true,
          ),
        ],
      ),
    );
  }

  Widget _headerRow() => _gridRow(
    height: 50,
    background: _blue,
    foreground: Colors.white,
    label: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        'KATEGORIE',
        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
      ),
    ),
    cells: [
      for (final player in state.players)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            player.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
    ],
  );

  Widget _sectionRow(String label, Color accent) => Container(
    height: 34,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.12),
      border: const Border(bottom: BorderSide(color: _ink, width: 1.5)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: accent,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _categoryRow(ScoreCategory category) {
    final face = category.isUpper
        ? String.fromCharCode(0x2680 + category.index)
        : null;
    return _gridRow(
      height: 48,
      label: Row(
        children: [
          if (face != null) ...[
            SizedBox(
              width: 34,
              child: Text(
                face,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 25, height: 1),
              ),
            ),
            const SizedBox(width: 2),
          ] else
            const SizedBox(width: 10),
          Expanded(
            child: Text(
              category.displayLabel(state.ruleSet),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          CategoryInfoButton(ruleSet: state.ruleSet, category: category),
        ],
      ),
      cells: [
        for (
          var playerIndex = 0;
          playerIndex < state.players.length;
          playerIndex++
        )
          _scoreCell(category, playerIndex),
      ],
    );
  }

  Widget _scoreCell(ScoreCategory category, int playerIndex) {
    final player = state.players[playerIndex];
    final score = player.scores[category];
    if (score != null) {
      return Semantics(
        label:
            '${category.displayLabel(state.ruleSet)} für ${player.name}: $score Punkte',
        child: Center(
          child: Text(
            '$score',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      label:
          '${category.displayLabel(state.ruleSet)} für ${player.name} eintragen',
      child: InkWell(
        key: Key('score-${category.name}-$playerIndex'),
        onTap: busy ? null : () => onEnterScore(category, playerIndex),
        child: const Center(child: Icon(Icons.add, size: 23, color: _blue)),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    List<int> values, {
    Color? accent,
    bool inverted = false,
  }) => _gridRow(
    height: 46,
    background: inverted ? accent : accent?.withValues(alpha: 0.1),
    foreground: inverted ? Colors.white : _ink,
    label: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    ),
    cells: [
      for (final value in values)
        Center(
          child: Text(
            '$value',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
    ],
  );

  Widget _gridRow({
    required double height,
    required Widget label,
    required List<Widget> cells,
    Color? background,
    Color foreground = _ink,
  }) => Container(
    color: background ?? _paper,
    child: DefaultTextStyle.merge(
      style: TextStyle(color: foreground),
      child: Row(
        children: [
          Container(
            width: _labelWidth,
            height: height,
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _ink)),
            ),
            child: label,
          ),
          for (final cell in cells)
            Container(
              width: _cellWidth,
              height: height,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: _ink),
                  bottom: BorderSide(color: _ink),
                ),
              ),
              child: cell,
            ),
        ],
      ),
    ),
  );
}
