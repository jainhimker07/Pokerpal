// lib/screens/group_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/group_model.dart';

class GroupDetailScreen extends StatelessWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  void _inviteFriends(BuildContext context) {
    final inviteText =
        'Join my group "${group.name}" on Casino Split 🎲\nUse this group code: ${group.id}';

    Share.share(inviteText);
  }

  void _startNewGame(BuildContext context) {
    // Placeholder for future functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Start game from group: Coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _inviteFriends(context),
            tooltip: 'Invite Friends',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Group Members',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: group.members.isEmpty
                  ? const Center(child: Text('No members added yet.'))
                  : ListView.separated(
                      itemCount: group.members.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final name = group.members[index];
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(name),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _startNewGame(context),
              icon: const Icon(Icons.play_circle_fill),
              label: const Text('Start New Game'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _inviteFriends(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Invite More Friends'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}