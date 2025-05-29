import 'package:flutter/material.dart';

class PlayerTile extends StatelessWidget {
  final String name;
  final double buyIn;

  const PlayerTile({
    super.key,
    required this.name,
    required this.buyIn,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      color: color.withAlpha(25), // Replaces withOpacity(0.1)
      child: ListTile(
        leading: const Icon(Icons.person, size: 28),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Buy-In: ₹${buyIn.toStringAsFixed(0)}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}