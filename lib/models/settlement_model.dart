class SettlementModel {
  final String name;
  final double buyIn;
  final double chipValue;
  final double finalChips;
  final double finalAmount;
  double netProfit; // ← remove `final`

  SettlementModel({
    required this.name,
    required this.buyIn,
    required this.chipValue,
    required this.finalChips,
    required this.finalAmount,
    required this.netProfit,
  });

  factory SettlementModel.clone(SettlementModel original) {
    return SettlementModel(
      name: original.name,
      buyIn: original.buyIn,
      chipValue: original.chipValue,
      finalChips: original.finalChips,
      finalAmount: original.finalAmount,
      netProfit: original.netProfit,
    );
  }
}