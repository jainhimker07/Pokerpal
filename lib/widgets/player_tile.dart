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
    return ListTile(
      title: Text(name),
      subtitle: Text('Buy-In: ₹${buyIn.toStringAsFixed(0)}'),
      leading: const Icon(Icons.person),
    );
  }
}