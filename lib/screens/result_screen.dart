import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import '../core/app_theme.dart';
import '../models/game_models.dart';
import '../widgets/totals_card.dart';
import 'block_game_screen.dart';
import 'digital_game_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({required this.game, super.key});
  final GameController game;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Future<void> _undo() async {
    await widget.game.undo();
    if (!mounted || widget.game.state.isComplete) return;
    final screen = widget.game.state.mode == GameMode.block
        ? BlockGameScreen(game: widget.game)
        : DigitalGameScreen(game: widget.game);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Future<void> _home() async {
    await widget.game.abandon();
    if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final winners = widget.game.winners;
    final tied = winners.length > 1;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 92,
                      color: AppColors.apricot,
                    ),
                    Text(
                      tied ? 'Gleichstand!' : 'Gewonnen!',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tied
                          ? winners.map((player) => player.name).join(' & ')
                          : '${winners.first.name} gewinnt mit ${winners.first.total} Punkten.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    TotalsCard(players: widget.game.state.players),
                    const SizedBox(height: 20),
                    if (widget.game.canUndo) ...[
                      OutlinedButton.icon(
                        onPressed: widget.game.isBusy ? null : _undo,
                        icon: const Icon(Icons.undo),
                        label: const Text('Letzten Eintrag rückgängig'),
                      ),
                      const SizedBox(height: 10),
                    ],
                    FilledButton.icon(
                      onPressed: widget.game.isBusy ? null : _home,
                      icon: const Icon(Icons.home),
                      label: const Text('Zur Startseite'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
