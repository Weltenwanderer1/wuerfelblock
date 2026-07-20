import 'package:flutter/material.dart';

import 'controllers/balut_controller.dart';
import 'controllers/game_controller.dart';
import 'controllers/qwixx_controller.dart';
import 'controllers/ten_thousand_controller.dart';
import 'core/app_theme.dart';
import 'models/balut_models.dart';
import 'models/game_models.dart';
import 'models/qwixx_models.dart';
import 'models/saved_game_state.dart';
import 'models/ten_thousand_models.dart';
import 'screens/balut_game_screen.dart';
import 'screens/balut_result_screen.dart';
import 'screens/block_game_screen.dart';
import 'screens/digital_game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/qwixx_game_screen.dart';
import 'screens/qwixx_result_screen.dart';
import 'screens/result_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/ten_thousand_game_screen.dart';
import 'screens/ten_thousand_digital_game_screen.dart';
import 'screens/ten_thousand_result_screen.dart';
import 'services/game_repository.dart';

class WuerfelblockApp extends StatelessWidget {
  const WuerfelblockApp({required this.repository, super.key});
  final GameRepository repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Würfelblock',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
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
  SavedGameState? saved;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload({bool showCorruptionMessage = false}) async {
    SavedGameState? loaded;
    String? corruptionReason;
    try {
      final result = await widget.repository.load();
      loaded = result.state;
      corruptionReason = result.corruptionReason;
    } catch (_) {
      loaded = null;
    }
    if (mounted) {
      setState(() {
        saved = loaded;
        loading = false;
      });
      if (showCorruptionMessage && corruptionReason != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(corruptionReason),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _openController(
    BuildContext context,
    Object controller, {
    bool replace = false,
  }) async {
    final Widget screen = switch (controller) {
      TenThousandController game =>
        game.state.isComplete
            ? TenThousandResultScreen(game: game)
            : game.state.mode == GameMode.digital
            ? TenThousandDigitalGameScreen(game: game)
            : TenThousandGameScreen(game: game),
      QwixxController game =>
        game.state.isComplete
            ? QwixxResultScreen(game: game)
            : QwixxGameScreen(game: game),
      BalutController game =>
        game.state.isComplete
            ? BalutResultScreen(game: game)
            : BalutGameScreen(game: game),
      GameController game =>
        game.state.isComplete
            ? ResultScreen(game: game)
            : game.state.mode == GameMode.block
            ? BlockGameScreen(game: game)
            : DigitalGameScreen(game: game),
      _ => throw ArgumentError('Unbekannter Spielcontroller.'),
    };
    final route = MaterialPageRoute<void>(builder: (_) => screen);
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
          onStarted: (controller) =>
              _openController(setupContext, controller, replace: true),
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
        if (state is QwixxGameState) {
          _openController(
            context,
            QwixxController(state: state, repository: widget.repository),
          );
        } else if (state is TenThousandGameState) {
          _openController(
            context,
            TenThousandController(state: state, repository: widget.repository),
          );
        } else if (state is BalutGameState) {
          _openController(
            context,
            BalutController(state: state, repository: widget.repository),
          );
        } else if (state is GameState) {
          _openController(
            context,
            GameController(state: state, repository: widget.repository),
          );
        }
      },
    );
  }
}
