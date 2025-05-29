import 'package:flutter/material.dart';
import '../utils/formatter.dart';
import '../services/settlement_service.dart';

class SettlementScreen extends StatelessWidget {
  const SettlementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final List<Map<String, dynamic>> players = List<Map<String, dynamic>>.from(args['players']);
    final double chipValue = args['chipValue'];
    final double cashValue = args['cashValue'];

    final double ratio = chipValue / cashValue;
    final settlementService = SettlementService();

    // Calculate player results
    final results = settlementService.calculateSettlements(
      players: players,
      chipToCashRatio: ratio,
    );

    // Intelligent "who owes whom" logic
    final transactions = settlementService.getSettlementTransactions(results);

    return Scaffold(
      appBar: AppBar(title: const Text('Settlement Summary')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Final Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final r = results[index];
                  final netText = r.netProfit > 0
                      ? '+${Formatter.currency(r.netProfit)}'
                      : Formatter.currency(r.netProfit);

                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(r.name),
                    subtitle: Text(
                      'Buy-In: ₹${r.buyIn.toStringAsFixed(0)}\n'
                      'Final Value: ₹${r.finalAmount.toStringAsFixed(0)}',
                    ),
                    trailing: Text(
                      netText,
                      style: TextStyle(
                        color: r.netProfit >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Who Owes Whom',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _ToggleableSettlement(transactions: transactions),
          ],
        ),
      ),
    );
  }
}

class _ToggleableSettlement extends StatefulWidget {
  final List<String> transactions;

  const _ToggleableSettlement({required this.transactions});

  @override
  State<_ToggleableSettlement> createState() => _ToggleableSettlementState();
}

class _ToggleableSettlementState extends State<_ToggleableSettlement> {
  bool showTransactions = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () {
            setState(() {
              showTransactions = !showTransactions;
            });
          },
          icon: const Icon(Icons.swap_horiz),
          label: Text(
            showTransactions ? 'Hide Settlements' : 'Show Who Owes Whom',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        if (showTransactions)
          ...widget.transactions.map(
            (t) => ListTile(
              leading: const Icon(Icons.arrow_forward),
              title: Text(t),
            ),
          ),
      ],
    );
  }
}