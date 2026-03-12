import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/game_model.dart';
import '../models/settlement_model.dart';

/// Stores completed games locally and provides lightweight progress stats.
class ProgressService {
  static const _storageKey = 'pokerpal_game_history_v1';
  static final ProgressService _instance = ProgressService._internal();

  factory ProgressService() => _instance;

  ProgressService._internal();

  /// Save a finished game with all player settlements.
  Future<void> recordGame({
    required double chipValue,
    required double cashValue,
    required List<SettlementModel> settlements,
    String? groupName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_storageKey) ?? [];

    final game = GameModel(
      id: const Uuid().v4(),
      groupId: groupName ?? 'solo',
      createdAt: DateTime.now(),
      chipValue: chipValue,
      cashValue: cashValue,
      results:
          settlements
              .map(
                (s) => PlayerResult(
                  name: s.name,
                  buyIn: s.buyIn,
                  finalChips: s.finalChips,
                  finalAmount: s.finalAmount,
                  netProfit: s.netProfit,
                  userId: s.userId,
                  email: s.email,
                ),
              )
              .toList(),
    );

    final encoded = jsonEncode(game.toMap());
    existing.add(encoded);
    await prefs.setStringList(_storageKey, existing);
  }

  /// Fetch all locally stored games.
  Future<List<GameModel>> loadGames() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_storageKey) ?? [];

    return existing
        .map(
          (raw) => GameModel.fromMap(jsonDecode(raw) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Clear history. Handy for debugging or a future settings screen.
  Future<void> clearGames() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
