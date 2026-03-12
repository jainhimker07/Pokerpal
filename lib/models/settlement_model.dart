class SettlementModel {
  final String name;
  final double buyIn;
  final double chipValue;
  final double finalChips;
  final double finalAmount;
  final String? userId;
  final String? email;
  double netProfit; // Mutable for transaction calculations

  SettlementModel({
    required this.name,
    required this.buyIn,
    required this.chipValue,
    required this.finalChips,
    required this.finalAmount,
    required this.netProfit,
    this.userId,
    this.email,
  });

  /// Creates a mutable clone for in-place transaction calculations
  factory SettlementModel.clone(SettlementModel original) {
    return SettlementModel(
      name: original.name,
      buyIn: original.buyIn,
      chipValue: original.chipValue,
      finalChips: original.finalChips,
      finalAmount: original.finalAmount,
      netProfit: original.netProfit,
      userId: original.userId,
      email: original.email,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'buyIn': buyIn,
      'chipValue': chipValue,
      'finalChips': finalChips,
      'finalAmount': finalAmount,
      'netProfit': netProfit,
      'userId': userId,
      'email': email,
    };
  }

  factory SettlementModel.fromMap(Map<String, dynamic> map) {
    return SettlementModel(
      name: map['name'],
      buyIn: map['buyIn'],
      chipValue: map['chipValue'],
      finalChips: map['finalChips'],
      finalAmount: map['finalAmount'],
      netProfit: map['netProfit'],
      userId: map['userId'],
      email: map['email'],
    );
  }
}
