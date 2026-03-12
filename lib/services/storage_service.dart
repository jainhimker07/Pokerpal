import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  /// Save game data locally using SharedPreferences
  Future<void> saveGameData(String gameId, Map<String, dynamic> gameData) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(gameData);
    await prefs.setString('game_$gameId', jsonString);
  }

  /// Load game data from local storage
  Future<Map<String, dynamic>?> loadGameData(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('game_$gameId');

    if (jsonString == null) return null;

    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Get all saved games (naive implementation by iterating keys)
  /// In a real app with many games, we might want a separate index.
  Future<List<Map<String, dynamic>>> getAllGames() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('game_'));
    final games = <Map<String, dynamic>>[];

    for (final key in keys) {
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        games.add(jsonDecode(jsonString) as Map<String, dynamic>);
      }
    }
    
    // Sort by creation time if possible, or leave unsorted
    return games;
  }

  /// Optional: Clear all saved game data
  Future<void> clearAllGameData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('game_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}