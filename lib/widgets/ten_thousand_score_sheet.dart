import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/ten_thousand_models.dart';

const tenThousandPaper = Color(0xFFFFF3D6);
const tenThousandInk = Color(0xFF2D2923);
const tenThousandAccent = Color(0xFF9A3412);
const tenThousandAccentSoft = Color(0xFFFFD6A5);

Future<int?> showTenThousandPointsDialog(
  BuildContext context, {
  required String playerName,
  int? initialPoints,
  bool restoring = false,
}) => showDialog<int>(
  context: context,
  builder: (context) => _PointsDialog(
    playerName: playerName,
    initialPoints: initialPoints,
    restoring: restoring,
  ),
);

Future<bool> confirmTenThousandDeletion(
  BuildContext context, {
  required int turnNumber,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        content: Text(
          'Zug $turnNumber bleibt im Protokoll sichtbar, zählt aber danach 0 Punkte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            key: const Key('confirm-delete'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    ) ??
    false;

Future<bool> confirmTenThousandTruncation(
  BuildContext context, {
  required int count,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partie endet früher'),
        content: Text(
          'Diese Korrektur beendet die Partie früher und entfernt $count spätere Einträge.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            key: const Key('confirm-truncation'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Korrektur bestätigen'),
          ),
        ],
      ),
    ) ??
    false;

class _PointsDialog extends StatefulWidget {
  const _PointsDialog({
    required this.playerName,
    required this.initialPoints,
    required this.restoring,
  });

  final String playerName;
  final int? initialPoints;
  final bool restoring;

  @override
  State<_PointsDialog> createState() => _PointsDialogState();
}

class _PointsDialogState extends State<_PointsDialog> {
  late final TextEditingController controller;
  String? error;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.initialPoints?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _save() {
    final points = int.tryParse(controller.text.trim());
    if (points == null || points < 0 || points % 50 != 0) {
      setState(() => error = 'Nur 0 oder positive Vielfache von 50.');
      return;
    }
    Navigator.pop(context, points);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.restoring
          ? 'Eintrag wiederherstellen'
          : widget.initialPoints == null
          ? 'Punkte eintragen'
          : 'Eintrag bearbeiten',
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Punkte für ${widget.playerName}'),
        const SizedBox(height: 10),
        TextField(
          key: const Key('points-field'),
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: 'Punkte',
            hintText: 'z. B. 350',
            errorText: error,
            helperText: '0 oder ein Vielfaches von 50',
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Abbrechen'),
      ),
      FilledButton(
        key: const Key('save-points'),
        onPressed: _save,
        child: Text(widget.restoring ? 'Wiederherstellen' : 'Speichern'),
      ),
    ],
  );
}

class TenThousandScoreSheet extends StatelessWidget {
  const TenThousandScoreSheet({
    required this.state,
    required this.onEdit,
    required this.onDelete,
    this.showSummary = true,
    super.key,
  });

  final TenThousandGameState state;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;
  final bool showSummary;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: tenThousandPaper,
      border: Border.all(color: tenThousandInk, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSummary) ...[
          _ScoreHeader(state: state),
          const _GridRule(),
          _Standings(state: state),
          const _GridRule(),
        ],
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Text(
            'ZUGPROTOKOLL',
            style: TextStyle(
              color: tenThousandAccent,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (state.turns.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Text('Noch keine Einträge.'),
          )
        else
          for (final turn in state.turns)
            _TurnRow(
              state: state,
              turn: turn,
              onEdit: () => onEdit(turn.ordinal),
              onDelete: turn.isDeleted ? null : () => onDelete(turn.ordinal),
            ),
      ],
    ),
  );
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.state});
  final TenThousandGameState state;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: tenThousandAccent,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.casino_outlined, color: Colors.white),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '10.000',
                style: TextStyle(
                  color: tenThousandInk,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'PUNKTEBLOCK · ECHTE WÜRFEL',
                style: TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        Text(
          '${state.turns.length} Züge',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _Standings extends StatelessWidget {
  const _Standings({required this.state});
  final TenThousandGameState state;

  String _status(int index) {
    if (state.isComplete) {
      return state.winnerIndices.contains(index) ? 'gewonnen' : 'beendet';
    }
    if (state.activePlayerIndex == index) return 'aktiv';
    if (state.isInFinalRound) {
      return state.finalRoundRemainingPlayerIndices.contains(index)
          ? 'letzter Versuch offen'
          : 'letzter Versuch beendet';
    }
    return 'wartet';
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < state.players.length; index++)
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: state.activePlayerIndex == index
                ? tenThousandAccentSoft.withValues(alpha: 0.7)
                : Colors.transparent,
            border: index == state.players.length - 1
                ? null
                : const Border(
                    bottom: BorderSide(color: tenThousandInk, width: 1),
                  ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.players[index].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      _status(index),
                      style: TextStyle(
                        color: state.activePlayerIndex == index
                            ? tenThousandAccent
                            : tenThousandInk.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${state.totals[index]}',
                style: const TextStyle(
                  color: tenThousandInk,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _TurnRow extends StatelessWidget {
  const _TurnRow({
    required this.state,
    required this.turn,
    required this.onEdit,
    required this.onDelete,
  });

  final TenThousandGameState state;
  final TenThousandTurn turn;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final owner = state.players[state.playerIndexForTurn(turn.ordinal)].name;
    final value = turn.isDeleted
        ? '${turn.points == 0 ? "Fehlwurf · 0" : turn.points} · gelöscht'
        : turn.points == 0
        ? 'Fehlwurf · 0'
        : '${turn.points}';
    return Semantics(
      button: true,
      label:
          'Zug ${turn.ordinal + 1}, $owner, $value. ${turn.isDeleted ? "Zum Wiederherstellen antippen" : "Zum Bearbeiten antippen"}',
      child: Material(
        key: Key('turn-${turn.ordinal}'),
        color: turn.isDeleted
            ? tenThousandInk.withValues(alpha: 0.08)
            : Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.only(left: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: tenThousandInk, width: 1)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '${turn.ordinal + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Expanded(
                  child: Text(
                    owner,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    value,
                    maxLines: 2,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      decoration: turn.isDeleted
                          ? TextDecoration.lineThrough
                          : null,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  key: Key('delete-turn-${turn.ordinal}'),
                  tooltip: turn.isDeleted
                      ? 'Eintrag ist gelöscht'
                      : 'Eintrag löschen',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 21),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridRule extends StatelessWidget {
  const _GridRule();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 2, child: ColoredBox(color: tenThousandInk));
}
