import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class BuyInScreen extends StatefulWidget {
  const BuyInScreen({super.key});

  @override
  State<BuyInScreen> createState() => _BuyInScreenState();
}

class _BuyInScreenState extends State<BuyInScreen> {
  List<Map<String, dynamic>> players = [];
  late double chipValue;
  late double cashValue;
  String? groupName;

  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _newNameController = TextEditingController();
  final TextEditingController _newBuyInController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    if (args == null) {
      // Handle the case where arguments are null
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Missing game data. Please restart the game.')),
        );
        Navigator.pop(context);
      });
      return;
    }
    if (players.isEmpty) { // Avoid reinitialization
      players = List<Map<String, dynamic>>.from(args['players'] ?? []);
    }
    chipValue = args['chipValue'] ?? 0.0;
    cashValue = args['cashValue'] ?? 0.0;
    groupName = args['groupName']; // optional

    for (final player in players) {
      if (!_controllers.containsKey(player['name'])) {
        _controllers[player['name']] = TextEditingController();
      }
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
    if (name.isEmpty || buyIn == null || buyIn <= 0) return;

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
      appBar: AppBar(
        title: const Text('Mid-Game Buy-Ins'),
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

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Current Buy-In: ₹${current.toStringAsFixed(0)}'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controllers[name],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Add Buy-In (₹)'),
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
                    ],
                  ),
                ),
              );
            }),
            const Divider(height: 40),
            const Text(
              'Add New Player',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newNameController,
              decoration: const InputDecoration(labelText: 'Player Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _newBuyInController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Buy-In (₹)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _addNewPlayer,
              icon: const Icon(Icons.person_add_alt_1),
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
                    if (groupName != null) 'groupName': groupName,
                  },
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Enter Final Chips'),
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