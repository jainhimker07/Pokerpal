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

  /// Optional: Clear all saved game data
  Future<void> clearAllGameData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('game_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}