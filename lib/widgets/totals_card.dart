import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/game_models.dart';

class TotalsCard extends StatelessWidget {
  const TotalsCard({required this.players, super.key});
  final List<Player> players;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gesamtstand', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final player in players)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      player.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${player.total}',
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
