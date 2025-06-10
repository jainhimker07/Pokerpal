import '../models/settlement_model.dart';

class SettlementService {
  /// Calculates net profit/loss per player based on buy-in and final chips
  List<SettlementModel> calculateSettlements({
    required List<Map<String, dynamic>> players,
    required double chipToCashRatio,
    String? groupId, // Optional: for logging or group tracking
  }) {
    List<SettlementModel> results = [];

    for (final player in players) {
      final name = player['name'];
      final double buyIn = player['buyIn'];
      final double finalChips = player['finalChips'] ?? player['exitChips'] ?? 0;

      final double expectedChips = buyIn * chipToCashRatio;
      final double netChips = finalChips - expectedChips;
      final double netProfit = netChips / chipToCashRatio;
      final double finalCash = finalChips / chipToCashRatio;

      results.add(SettlementModel(
        name: name,
        buyIn: buyIn,
        chipValue: chipToCashRatio,
        finalChips: finalChips,
        finalAmount: finalCash,
        netProfit: netProfit,
      ));
    }

    return results;
  }

  /// Generates a list of “who owes whom” transactions
  List<String> getSettlementTransactions(List<SettlementModel> results) {
    final creditors = <SettlementModel>[];
    final debtors = <SettlementModel>[];

    for (var r in results) {
      if (r.netProfit > 0.01) creditors.add(SettlementModel.clone(r));
      if (r.netProfit < -0.01) debtors.add(SettlementModel.clone(r));
    }

    creditors.sort((a, b) => b.netProfit.compareTo(a.netProfit));
    debtors.sort((a, b) => a.netProfit.compareTo(b.netProfit));

    final transactions = <String>[];

    int i = 0;
    int j = 0;

    while (i < debtors.length && j < creditors.length) {
      final debtor = debtors[i];
      final creditor = creditors[j];

      final owed = debtor.netProfit.abs();
      final available = creditor.netProfit;
      final amount = owed < available ? owed : available;

      if (amount > 0.01) {
        transactions.add('${debtor.name} pays ₹${amount.toStringAsFixed(0)} to ${creditor.name}');
      }

      debtor.netProfit += amount;
      creditor.netProfit -= amount;

      if (debtor.netProfit.abs() < 1) i++;
      if (creditor.netProfit.abs() < 1) j++;
    }

    return transactions;
  }

  /// Optional: Generates a summary string for sharing
  String generateSummaryText({
    required List<SettlementModel> results,
    required List<String> transactions,
    String? groupName,
  }) {
    final buffer = StringBuffer();

    if (groupName != null) buffer.writeln('💰 Group: $groupName\n');

    buffer.writeln('🔍 Final Summary:');
    for (var r in results) {
      final net = r.netProfit >= 0 ? '+₹${r.netProfit.toStringAsFixed(0)}' : '₹${r.netProfit.toStringAsFixed(0)}';
      buffer.writeln('${r.name}: $net (Buy-In ₹${r.buyIn.toStringAsFixed(0)}, Final ₹${r.finalAmount.toStringAsFixed(0)})');
    }

    buffer.writeln('\n🤝 Who Owes Whom:');
    if (transactions.isEmpty) {
      buffer.writeln('All settled. No dues.');
    } else {
      for (var t in transactions) {
        buffer.writeln(t);
      }
    }

    return buffer.toString().trim();
  }
}