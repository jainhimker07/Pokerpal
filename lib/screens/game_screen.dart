import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _chipController = TextEditingController();
  final TextEditingController _cashController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _buyInController = TextEditingController();

  List<Map<String, dynamic>> players = [];
  String? groupName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && args.containsKey('groupName')) {
      groupName = args['groupName'];
    }
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    final buyIn = double.tryParse(_buyInController.text.trim());

    if (name.isEmpty || buyIn == null || buyIn <= 0) return;

    setState(() {
      players.add({'name': name, 'buyIn': buyIn});
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
        if (groupName != null) 'groupName': groupName,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: ListView(
          children: [
            const Text(
              'Chip-to-Cash Ratio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chipController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Chips (e.g. 1000)',
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('='),
                ),
                Expanded(
                  child: TextField(
                    controller: _cashController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cash (e.g. ₹100)',
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Player Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _buyInController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Initial Buy-In (₹)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _addPlayer,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Player'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Players',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (players.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No players added yet.', style: TextStyle(color: Colors.grey)),
              )
            else
              Column(
                children: players
                    .map(
                      (player) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(player['name']),
                          subtitle: Text('Buy-In: ₹${player['buyIn']}'),
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _continueToGame,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Continue to Game'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}