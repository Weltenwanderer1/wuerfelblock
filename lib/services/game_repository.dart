import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/balut_models.dart';
import '../models/escalero_models.dart';
import '../models/game_models.dart';
import '../models/qwixx_models.dart';
import '../models/saved_game_state.dart';
import '../models/ten_thousand_models.dart';

class LoadResult {
  const LoadResult({this.state, this.corruptionReason});
  final SavedGameState? state;
  final String? corruptionReason;

  bool get hadCorruption => corruptionReason != null;
}

abstract class GameRepository {
  Future<void> save(SavedGameState state);
  Future<LoadResult> load();
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
  Future<LoadResult> load() async {
    final value = preferences.getString(key);
    if (value == null) return const LoadResult();
    try {
      return LoadResult(
        state: decodeSavedGameState(jsonDecode(value) as Map<String, dynamic>),
      );
    } catch (error) {
      try {
        await clear();
      } catch (_) {
        // Ein defekter Save darf den App-Start nicht blockieren.
      }
      return LoadResult(
        state: null,
        corruptionReason: _describeCorruption(value, error),
      );
    }
  }

  @override
  Future<void> clear() async {
    final cleared = await preferences.remove(key);
    if (!cleared) throw StateError('Spielstand konnte nicht gelöscht werden.');
  }
}

class MemoryGameRepository implements GameRepository {
  Object? backingStore; // raw string (simulates corrupted payload) or null
  SavedGameState? saved;

  @override
  Future<void> save(SavedGameState state) async {
    saved = decodeSavedGameState(state.toJson());
  }

  @override
  Future<LoadResult> load() async {
    if (backingStore is String) {
      final raw = backingStore as String;
      try {
        return LoadResult(
          state: decodeSavedGameState(jsonDecode(raw) as Map<String, dynamic>),
        );
      } catch (error) {
        backingStore = null;
        return LoadResult(
          state: null,
          corruptionReason: _describeCorruption(raw, error),
        );
      }
    }
    final existing = saved;
    if (existing == null) return const LoadResult();
    return LoadResult(state: decodeSavedGameState(existing.toJson()));
  }

  @override
  Future<void> clear() async {
    saved = null;
    backingStore = null;
  }
}

String _describeCorruption(String raw, Object error) {
  final preview = raw.length > 32 ? '${raw.substring(0, 32)}…' : raw;
  if (error is FormatException) {
    return 'Spielstand war beschädigt (${error.message}, $preview) und wurde verworfen.';
  }
  return 'Spielstand war beschädigt ($error, $preview) und wurde verworfen.';
}

SavedGameState decodeSavedGameState(Map<String, dynamic> json) =>
    switch (json['type']) {
      null || 'classic' => GameState.fromJson(json),
      'qwixx' => QwixxGameState.fromJson(json),
      'tenThousand' => TenThousandGameState.fromJson(json),
      'balut' => BalutGameState.fromJson(json),
      'escalero' => EscaleroGameState.fromJson(json),
      _ => throw FormatException('Unbekannter Spieltyp: ${json['type']}'),
    };
