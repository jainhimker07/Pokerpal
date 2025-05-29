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
}