import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/game_model.dart';
import '../models/settlement_model.dart';

/// Stores completed games locally (SharedPreferences) AND in Firestore (poker-split collection).
class ProgressService {
  static const _storageKey = 'pokerpal_game_history_v1';
  static final ProgressService _instance = ProgressService._internal();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  factory ProgressService() => _instance;

  ProgressService._internal();

  /// Save a finished game with all player settlements.
  /// Writes to both SharedPreferences (for local perf tab) and Firestore poker-split collection.
  Future<void> recordGame({
    required double chipValue,
    required double cashValue,
    required List<SettlementModel> settlements,
    required List<Map<String, dynamic>> players, // Original player maps with userId, code, etc.
    String? groupName,
    String? roomName,
  }) async {
    final gameId = const Uuid().v4();
    final now = DateTime.now();

    final game = GameModel(
      id: gameId,
      groupId: groupName ?? 'solo',
      roomName: (roomName != null && roomName.trim().isNotEmpty)
          ? roomName
          : 'Unnamed Room',
      createdAt: now,
      chipValue: chipValue,
      cashValue: cashValue,
      results: settlements
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

    // 1. Save to local SharedPreferences (for Performance tab + Recent Games)
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_storageKey) ?? [];
    final encoded = jsonEncode(game.toMap());
    existing.add(encoded);
    await prefs.setStringList(_storageKey, existing);

    // 2. Save to Firestore poker-split collection with full player objects
    final currentUser = FirebaseAuth.instance.currentUser;

    // Build detailed players list for Firestore
    final firestorePlayers = settlements.map((s) {
      // Find original player map to get code and avatarColor
      final originalPlayer = players.firstWhere(
        (p) => p['name'] == s.name,
        orElse: () => <String, dynamic>{},
      );

      return {
        'name': s.name,
        'buyIn': s.buyIn,
        'cashOut': s.finalAmount,
        'net': s.netProfit,
        'finalChips': s.finalChips,
        if (s.userId != null) 'uid': s.userId,
        if (s.email != null) 'email': s.email,
        if (originalPlayer['code'] != null) 'code': originalPlayer['code'],
        'isHost': originalPlayer['isHost'] ?? false,
      };
    }).toList();

    await _db.collection('poker-split').doc(gameId).set({
      'GameID': gameId,
      'date': Timestamp.fromDate(now),
      'roomName': game.roomName,
      'groupId': groupName ?? 'solo',
      'chipValue': chipValue,
      'cashValue': cashValue,
      'players': firestorePlayers,
      'playerCount': firestorePlayers.length,
      // hostUid: the logged-in user who initiated the settlement
      if (currentUser != null) 'hostUid': currentUser.uid,
      // Array of all linked uids for easy querying
      'linkedUids': firestorePlayers
          .where((p) => p['uid'] != null)
          .map((p) => p['uid'] as String)
          .toList(),
    });
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
