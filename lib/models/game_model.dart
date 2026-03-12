class GameModel {
  final String id;
  final String groupId;
  final String roomName;
  final DateTime createdAt;
  final double chipValue; // e.g., 500
  final double cashValue; // e.g., 100
  final List<PlayerResult> results;

  GameModel({
    required this.id,
    required this.groupId,
    this.roomName = 'No Name',
    required this.createdAt,
    required this.chipValue,
    required this.cashValue,
    required this.results,
  });

  double get ratio => chipValue / cashValue;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'roomName': roomName,
      'createdAt': createdAt.toIso8601String(),
      'chipValue': chipValue,
      'cashValue': cashValue,
      'results': results.map((r) => r.toMap()).toList(),
    };
  }

  factory GameModel.fromMap(Map<String, dynamic> map) {
    return GameModel(
      id: map['id'],
      groupId: map['groupId'],
      roomName: map['roomName'] ?? 'No Name',
      createdAt: DateTime.parse(map['createdAt']),
      chipValue: map['chipValue'],
      cashValue: map['cashValue'],
      results: List<Map<String, dynamic>>.from(
        map['results'],
      ).map((r) => PlayerResult.fromMap(r)).toList(),
    );
  }
}

class PlayerResult {
  final String name;
  final double buyIn;
  final double finalChips;
  final double finalAmount;
  final double netProfit;
  final String? userId;
  final String? email;

  PlayerResult({
    required this.name,
    required this.buyIn,
    required this.finalChips,
    required this.finalAmount,
    required this.netProfit,
    this.userId,
    this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'buyIn': buyIn,
      'finalChips': finalChips,
      'finalAmount': finalAmount,
      'netProfit': netProfit,
      'userId': userId,
      'email': email,
    };
  }

  factory PlayerResult.fromMap(Map<String, dynamic> map) {
    return PlayerResult(
      name: map['name'],
      buyIn: map['buyIn'],
      finalChips: map['finalChips'],
      finalAmount: map['finalAmount'],
      netProfit: map['netProfit'],
      userId: map['userId'],
      email: map['email'],
    );
  }
}
