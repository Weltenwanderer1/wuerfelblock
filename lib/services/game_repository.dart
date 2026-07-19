import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_models.dart';
import '../models/qwixx_models.dart';
import '../models/saved_game_state.dart';
import '../models/ten_thousand_models.dart';

abstract class GameRepository {
  Future<void> save(SavedGameState state);
  Future<SavedGameState?> load();
  Future<void> clear();
}

class SharedPreferencesGameRepository implements GameRepository {
  SharedPreferencesGameRepository(this.preferences);
  static const key = 'active_game_v1';
  final SharedPreferences preferences;

  @override
  Future<void> save(SavedGameState state) async {
    final saved = await preferences.setString(key, jsonEncode(state.toJson()));
    if (!saved) throw StateError('Spielstand konnte nicht gespeichert werden.');
  }

  @override
  Future<SavedGameState?> load() async {
    final value = preferences.getString(key);
    if (value == null) return null;
    try {
      return decodeSavedGameState(jsonDecode(value) as Map<String, dynamic>);
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
  SavedGameState? saved;

  @override
  Future<void> save(SavedGameState state) async {
    saved = decodeSavedGameState(state.toJson());
  }

  @override
  Future<SavedGameState?> load() async =>
      saved == null ? null : decodeSavedGameState(saved!.toJson());

  @override
  Future<void> clear() async => saved = null;
}

SavedGameState decodeSavedGameState(Map<String, dynamic> json) =>
    switch (json['type']) {
      null || 'classic' => GameState.fromJson(json),
      'qwixx' => QwixxGameState.fromJson(json),
      'tenThousand' => TenThousandGameState.fromJson(json),
      _ => throw FormatException('Unbekannter Spieltyp: ${json['type']}'),
    };
