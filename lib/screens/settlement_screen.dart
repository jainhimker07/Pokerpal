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
    final String? groupName = args['groupName'];

    final double ratio = chipValue / cashValue;
    final settlementService = SettlementService();

    final results = settlementService.calculateSettlements(
      players: players,
      chipToCashRatio: ratio,
    );

    final transactions = settlementService.getSettlementTransactions(results);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlement Summary'),
        centerTitle: true,
        bottom: groupName != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Group: $groupName',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            const Text(
              'Final Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final r = results[index];
                  final netText = r.netProfit > 0
                      ? '+${Formatter.currency(r.netProfit)}'
                      : Formatter.currency(r.netProfit);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple.shade100,
                        child: const Icon(Icons.person, color: Colors.deepPurple),
                      ),
                      title: Text(
                        r.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Buy-In: ₹${r.buyIn.toStringAsFixed(0)}\n'
                        'Final Value: ₹${r.finalAmount.toStringAsFixed(0)}',
                      ),
                      trailing: Text(
                        netText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: r.netProfit >= 0 ? Colors.green : Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 32),
            const SizedBox(height: 8),
            const Text(
              'Who Owes Whom',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
          icon: Icon(
            showTransactions ? Icons.visibility_off : Icons.visibility,
            color: Colors.deepPurple,
          ),
          label: Text(
            showTransactions ? 'Hide Settlements' : 'Show Who Owes Whom',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        if (showTransactions)
          ...widget.transactions.map(
            (t) => Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, color: Colors.deepPurple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}