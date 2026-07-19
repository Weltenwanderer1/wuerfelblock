import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/game_models.dart';

class TotalsCard extends StatelessWidget {
  const TotalsCard({required this.state, super.key});
  final GameState state;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gesamtstand', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final player in state.players)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${state.totalFor(player)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.plum,
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
