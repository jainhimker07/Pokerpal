import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final List<Map<String, dynamic>> players =
        List<Map<String, dynamic>>.from(args['players']);
    final double chipValue = args['chipValue'];
    final double cashValue = args['cashValue'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Final Chips'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: players.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final player = players[index];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Final Chips',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          player['finalChips'] = double.tryParse(value) ?? 0;
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/settlement',
                  arguments: {
                    'players': players,
                    'chipValue': chipValue,
                    'cashValue': cashValue,
                  },
                );
              },
              icon: const Icon(Icons.calculate),
              label: const Text('Calculate Settlement'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}