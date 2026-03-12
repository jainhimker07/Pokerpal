import 'package:flutter/material.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late List<Map<String, dynamic>> players;
  String? groupName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    players = List<Map<String, dynamic>>.from(args['players']);
    groupName = args['groupName']; // optional
  }

  void _exitPlayer(int index) {
    final player = players[index];
    final name = player['name'];
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Exit $name'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Final Chips Taken',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final chips = double.tryParse(controller.text.trim()) ?? 0;
              setState(() {
                player['exitChips'] = chips;
                player['exited'] = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Confirm Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupName != null ? 'Players – $groupName' : 'Players'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index];
            final name = player['name'];
            final buyIn = player['buyIn'];
            final exited = player['exited'] == true;
            final chipOut = player['exitChips'];

            return Card(
              child: ListTile(
                title: Text(name),
                subtitle: Text(
                  exited
                      ? 'Exited with ${chipOut.toStringAsFixed(0)} chips'
                      : 'Buy-In: ₹${buyIn.toStringAsFixed(0)}',
                ),
                trailing: exited
                    ? const Icon(Icons.check, color: Colors.grey)
                    : TextButton(
                        onPressed: () => _exitPlayer(index),
                        child: const Text('Exit'),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
