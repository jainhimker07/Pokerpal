import 'dart:math';

class Helpers {
  static String generateGameId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'game_$timestamp$random';
  }

  static double parseInput(String input) {
    return double.tryParse(input.trim()) ?? 0.0;
  }
}