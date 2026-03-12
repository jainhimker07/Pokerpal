// lib/widgets/group_tile.dart

import 'package:flutter/material.dart';
import '../models/group_model.dart';

class GroupTile extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onTap;

  const GroupTile({super.key, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: const CircleAvatar(child: Icon(Icons.group)),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${group.members.length} members'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      ),
    );
  }
}
