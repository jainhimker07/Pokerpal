class GameModel {
  final String id;
  final DateTime createdAt;
  final double chipValue; // e.g., 500
  final double cashValue; // e.g., 100

  GameModel({
    required this.id,
    required this.createdAt,
    required this.chipValue,
    required this.cashValue,
  });

  double get ratio => chipValue / cashValue;
}