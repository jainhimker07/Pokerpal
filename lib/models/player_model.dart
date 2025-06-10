class PlayerModel {
  final String name;
  final List<double> buyIns;
  double? exitChips;

  PlayerModel({
    required this.name,
    required this.buyIns,
    this.exitChips,
  });

  double get totalBuyIn => buyIns.fold(0, (sum, b) => sum + b);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'buyIns': buyIns,
      'exitChips': exitChips,
    };
  }

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      name: map['name'],
      buyIns: List<double>.from(map['buyIns']),
      exitChips: map['exitChips']?.toDouble(),
    );
  }
}