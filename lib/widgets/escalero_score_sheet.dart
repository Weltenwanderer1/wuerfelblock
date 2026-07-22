import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';

import '../models/escalero_models.dart';

/// Responsive 10 × 3 Escalero score sheet for one selected player.
class EscaleroScoreSheet extends StatelessWidget {
  const EscaleroScoreSheet({
    required this.state,
    required this.playerIndex,
    required this.onCellTap,
    required this.canTapEmptyCells,
    required this.onCategoryTap,
    super.key,
  });

  final EscaleroGameState state;
  final int playerIndex;
  final void Function(EscaleroCategory category, int column)? onCellTap;
  final bool canTapEmptyCells;
  final ValueChanged<EscaleroCategory> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final player = state.players[playerIndex];
    return Semantics(
      label: localizeText(context, 'Escalero-Wertungsblatt für ${player.name}'),
      child: Card(
        key: const Key('escalero-sheet'),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              color: const Color(0xFF5B2A1D),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  for (var column = 0; column < 3; column++)
                    Expanded(
                      flex: 2,
                      child: LocalizedText(
                        '${1 << column} P',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: EscaleroCategory.values.length,
                itemBuilder: (context, row) {
                  final category = EscaleroCategory.values[row];
                  return Container(
                    color: row.isEven
                        ? const Color(0xFFFFFBF1)
                        : const Color(0xFFFFF2DA),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: InkWell(
                            key: Key('escalero-info-${category.name}'),
                            onTap: () => onCategoryTap(category),
                            borderRadius: BorderRadius.circular(7),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: LocalizedText(
                                      category.label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.info_outline, size: 17),
                                ],
                              ),
                            ),
                          ),
                        ),
                        for (var column = 0; column < 3; column++)
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: _ScoreCell(
                                key: Key(
                                  'escalero-${state.mode.name == 'digital' ? 'score' : 'edit'}-${category.name}-$column',
                                ),
                                category: category,
                                column: column,
                                playerName: player.name,
                                value: player.entries[category]![column],
                                onTap:
                                    onCellTap != null &&
                                        (player.entries[category]![column] !=
                                                null ||
                                            canTapEmptyCells)
                                    ? () => onCellTap!(category, column)
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              color: const Color(0xFFFFE0A8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Row(
                children: [
                  const Expanded(
                    flex: 4,
                    child: LocalizedText(
                      'Summe',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  for (var column = 0; column < 3; column++)
                    Expanded(
                      flex: 2,
                      child: LocalizedText(
                        '${player.columnTotal(column)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCell extends StatelessWidget {
  const _ScoreCell({
    required this.category,
    required this.column,
    required this.playerName,
    required this.value,
    required this.onTap,
    super.key,
  });
  final EscaleroCategory category;
  final int column;
  final String playerName;
  final int? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final categoryName = localizeText(context, category.label);
    final score = value == null
        ? localizeText(context, 'frei')
        : '$value ${localizeText(context, 'Punkte')}';
    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label:
          '$categoryName, ${localizeText(context, 'Kolonne')} ${column + 1}, '
          '$playerName: $score',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: value == null ? Colors.white : const Color(0xFFFFD58A),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xFFB88955)),
          ),
          child: LocalizedText(
            value?.toString() ?? '·',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}
