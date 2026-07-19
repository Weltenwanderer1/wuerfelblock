import 'package:flutter/material.dart';

import 'controllers/game_controller.dart';
import 'core/app_theme.dart';
import 'models/game_models.dart';
import 'screens/block_game_screen.dart';
import 'screens/digital_game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/rules_screen.dart';
import 'screens/result_screen.dart';
import 'screens/setup_screen.dart';
import 'services/game_repository.dart';

class WuerfelblockApp extends StatelessWidget {
  const WuerfelblockApp({required this.repository, super.key});
  final GameRepository repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Würfelblock',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    routes: {'/rules': (_) => const RulesScreen()},
    home: _HomeHost(repository: repository),
  );
}

class _HomeHost extends StatefulWidget {
  const _HomeHost({required this.repository});
  final GameRepository repository;
  @override
  State<_HomeHost> createState() => _HomeHostState();
}

class _HomeHostState extends State<_HomeHost> {
  GameState? saved;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    GameState? loaded;
    try {
      loaded = await widget.repository.load();
    } catch (_) {
      loaded = null;
    }
    if (mounted) {
      setState(() {
        saved = loaded;
        loading = false;
      });
    }
  }

  Future<void> _openGame(
    BuildContext context,
    GameController game, {
    bool replace = false,
  }) async {
    final route = MaterialPageRoute<void>(
      builder: (_) => game.state.isComplete
          ? ResultScreen(game: game)
          : game.state.mode == GameMode.block
          ? BlockGameScreen(game: game)
          : DigitalGameScreen(game: game),
    );
    if (replace) {
      await Navigator.pushReplacement(context, route);
    } else {
      await Navigator.push(context, route);
    }
    await _reload();
  }

  Future<void> _newGame() async {
    if (saved != null) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Gespeicherte Partie verwerfen?'),
          content: const Text(
            'Wenn du neu startest, wird die laufende Partie gelöscht.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Verwerfen'),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (setupContext) => SetupScreen(
          repository: widget.repository,
          onStarted: (game) => _openGame(setupContext, game, replace: true),
        ),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return HomeScreen(
      savedGame: saved,
      onNewGame: _newGame,
      onContinue: () {
        final state = saved;
        if (state != null) {
          _openGame(
            context,
            GameController(state: state, repository: widget.repository),
          );
        }
      },
    );
  }
}
