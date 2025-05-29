import 'package:flutter/material.dart';

class AddPlayerScreen extends StatefulWidget {
  const AddPlayerScreen({super.key});

  @override
  State<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _buyInController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _buyInController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final buyIn = double.tryParse(_buyInController.text.trim()) ?? 0;

    if (name.isEmpty || buyIn <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid data')),
      );
      return;
    }

    Navigator.pop(context, {
      'name': name,
      'buyIn': buyIn,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Player')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Player Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _buyInController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Initial Buy-In (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Add Player'),
            )
          ],
        ),
      ),
    );
  }
}