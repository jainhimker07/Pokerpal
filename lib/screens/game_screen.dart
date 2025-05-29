import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _chipController = TextEditingController();
  final TextEditingController _cashController = TextEditingController();

  List<Map<String, dynamic>> players = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _buyInController = TextEditingController();

  void _addPlayer() {
    final name = _nameController.text.trim();
    final buyIn = double.tryParse(_buyInController.text.trim());

    if (name.isEmpty || buyIn == null || buyIn <= 0) return;

    setState(() {
      players.add({
        'name': name,
        'buyIn': buyIn,
      });
    });

    _nameController.clear();
    _buyInController.clear();
  }

  void _continueToGame() {
    final chip = double.tryParse(_chipController.text.trim());
    final cash = double.tryParse(_cashController.text.trim());

    if (players.isEmpty || chip == null || cash == null || chip <= 0 || cash <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid ratio and add players')),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/buyins',
      arguments: {
        'players': players,
        'chipValue': chip,
        'cashValue': cash,
      },
    );
  }

  @override
  void dispose() {
    _chipController.dispose();
    _cashController.dispose();
    _nameController.dispose();
    _buyInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Game'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              'Chip-to-Cash Ratio',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chipController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Chips (e.g. 500)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('='),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cashController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cash (e.g. ₹100)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Add Player',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Player Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _buyInController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Initial Buy-In (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _addPlayer,
              child: const Text('Add Player'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Players',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (players.isEmpty)
              const Text('No players added yet.')
            else
              Column(
                children: players
                    .map((player) => ListTile(
                          title: Text(player['name']),
                          subtitle: Text('Buy-In: ₹${player['buyIn']}'),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _continueToGame,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Continue to Game'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}