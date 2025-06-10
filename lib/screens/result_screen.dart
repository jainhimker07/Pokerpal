import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final List<Map<String, dynamic>> players = List<Map<String, dynamic>>.from(args['players']);
    final double chipValue = args['chipValue'];
    final double cashValue = args['cashValue'];
    final String? groupName = args['groupName'];

    final double ratio = chipValue / cashValue;

    // Calculate total buy-in in chips
    final double totalChipBuyIn = players.fold(
      0.0,
      (sum, p) => sum + ((p['buyIn'] as double) * ratio),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Final Chips'),
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
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Final Chips',
                            ),
                            onChanged: (value) {
                              player['finalChips'] = double.tryParse(value) ?? 0;
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) => ElevatedButton.icon(
                onPressed: () {
                  final double totalFinalChips = players.fold(
                    0.0,
                    (sum, p) => sum + (p['finalChips'] ?? 0),
                  );

                  if ((totalFinalChips - totalChipBuyIn).abs() > 0.01) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Mismatch! Final chips total (${totalFinalChips.toStringAsFixed(0)}) ≠ Buy-in total (${totalChipBuyIn.toStringAsFixed(0)})',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pushNamed(
                    context,
                    '/settlement',
                    arguments: {
                      'players': players,
                      'chipValue': chipValue,
                      'cashValue': cashValue,
                      if (groupName != null) 'groupName': groupName,
                    },
                  );
                },
                icon: const Icon(Icons.calculate),
                label: const Text('Calculate Settlement'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}