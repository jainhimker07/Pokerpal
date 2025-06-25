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
  final List<TextEditingController> _memberControllers = [];

  bool isCreating = false;

  void _addMemberField() {
    setState(() {
      _memberControllers.add(TextEditingController());
    });
  }

  void _createGroup() async {
    final groupName = _nameController.text.trim();
    final yourName = _yourNameController.text.trim();
    final members = _memberControllers.map((c) => c.text.trim()).where((name) => name.isNotEmpty).toList();

    if (groupName.isEmpty || yourName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => isCreating = true);

    final String groupId = const Uuid().v4();

    // Add the creator to the members list
    members.insert(0, yourName);

    // Call updated GroupService method
    GroupService().createGroup(
      groupId,
      groupName,
      members, // Include all members
      [],         // Start with empty gameIds
    );

    final inviteText =
        'Join my game group "$groupName" on Casino Split 🎲\nDownload the app and use this group code: $groupId';

    await Share.share(inviteText);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yourNameController.dispose();
    for (final controller in _memberControllers) {
      controller.dispose();
    }
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
            const SizedBox(height: 16),
            ..._memberControllers.map((controller) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Member Name',
                  border: OutlineInputBorder(),
                ),
              ),
            )),
            TextButton(
              onPressed: _addMemberField,
              child: const Text('Add Member'),
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