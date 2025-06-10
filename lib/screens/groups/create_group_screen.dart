// lib/screens/groups/create_group_screen.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/group_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _yourNameController = TextEditingController();

  bool isCreating = false;

  void _createGroup() async {
    final groupName = _nameController.text.trim();
    final yourName = _yourNameController.text.trim();

    if (groupName.isEmpty || yourName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => isCreating = true);

    final String groupId = const Uuid().v4();

    // ✅ Corrected to pass 3 arguments: id, name, members (as List<String>)
    GroupService().createGroup(groupId, groupName, [yourName]);

    final inviteText =
        'Join my game group "$groupName" on Casino Split 🎲\nDownload the app and use this group code: $groupId';

    await Share.share(inviteText);

    if (context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yourNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _yourNameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isCreating ? null : _createGroup,
              icon: const Icon(Icons.check),
              label: Text(isCreating ? 'Creating...' : 'Create Group'),
            ),
          ],
        ),
      ),
    );
  }
}