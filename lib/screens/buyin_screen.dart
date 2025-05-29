import 'package:flutter/material.dart';

class BuyInScreen extends StatefulWidget {
  const BuyInScreen({super.key});

  @override
  State<BuyInScreen> createState() => _BuyInScreenState();
}

class _BuyInScreenState extends State<BuyInScreen> {
  late List<Map<String, dynamic>> players;
  late double chipValue;
  late double cashValue;

  final Map<String, TextEditingController> _controllers = {};

  final TextEditingController _newNameController = TextEditingController();
  final TextEditingController _newBuyInController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    players = List<Map<String, dynamic>>.from(args['players']);
    chipValue = args['chipValue'];
    cashValue = args['cashValue'];

    for (final player in players) {
      _controllers[player['name']] = TextEditingController();
    }
  }

  void _addBuyIn(String name, double amount) {
    final player = players.firstWhere((p) => p['name'] == name);
    setState(() {
      player['buyIn'] += amount;
    });
    _controllers[name]!.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ₹${amount.toInt()} to $name')),
    );
  }

  void _addNewPlayer() {
    final name = _newNameController.text.trim();
    final buyIn = double.tryParse(_newBuyInController.text.trim());
    if (name.isEmpty || buyIn == null) return;

    setState(() {
      players.add({'name': name, 'buyIn': buyIn});
      _controllers[name] = TextEditingController();
    });

    _newNameController.clear();
    _newBuyInController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added new player $name')),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _newNameController.dispose();
    _newBuyInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mid-Game Buy-Ins')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Add Buy-In for Players',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...players.map((player) {
              final name = player['name'];
              final current = player['buyIn'];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$name', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Buy-In: ₹${current.toStringAsFixed(0)}'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controllers[name],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Add Buy-In (₹)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          final value = double.tryParse(_controllers[name]!.text.trim());
                          if (value != null && value > 0) {
                            _addBuyIn(name, value);
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),
            const Divider(height: 32),
            const Text(
              'Add New Player',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _newNameController,
              decoration: const InputDecoration(
                labelText: 'Player Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _newBuyInController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Buy-In (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addNewPlayer,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Player'),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/result',
                  arguments: {
                    'players': players,
                    'chipValue': chipValue,
                    'cashValue': cashValue,
                  },
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Enter Final Chips'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}