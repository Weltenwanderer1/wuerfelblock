import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_models.dart';

abstract class GameRepository {
  Future<void> save(GameState state);
  Future<GameState?> load();
  Future<void> clear();
}

class SharedPreferencesGameRepository implements GameRepository {
  SharedPreferencesGameRepository(this.preferences);
  static const key = 'active_game_v1';
  final SharedPreferences preferences;

  @override
  Future<void> save(GameState state) async {
    final saved = await preferences.setString(key, jsonEncode(state.toJson()));
    if (!saved) throw StateError('Spielstand konnte nicht gespeichert werden.');
  }

  @override
  Future<GameState?> load() async {
    final value = preferences.getString(key);
    if (value == null) return null;
    try {
      return GameState.fromJson(jsonDecode(value) as Map<String, dynamic>);
    } catch (_) {
      try {
        await clear();
      } catch (_) {
        // Ein defekter Save darf den App-Start nicht blockieren.
      }
      return null;
    }
  }

  @override
  Future<void> clear() async {
    final cleared = await preferences.remove(key);
    if (!cleared) throw StateError('Spielstand konnte nicht gelöscht werden.');
  }
}

class MemoryGameRepository implements GameRepository {
  GameState? saved;
  @override
  Future<void> save(GameState state) async {
    saved = GameState.fromJson(state.toJson());
  }

  @override
  Future<GameState?> load() async =>
      saved == null ? null : GameState.fromJson(saved!.toJson());

  @override
  Future<void> clear() async => saved = null;
}
