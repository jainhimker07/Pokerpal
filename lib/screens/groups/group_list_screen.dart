// lib/screens/group_list_screen.dart

import 'package:flutter/material.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import 'group_detail_screen.dart';
import 'create_group_screen.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  List<GroupModel> groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final loadedGroups = await GroupService().getAllGroups();
    setState(() {
      groups = loadedGroups;
    });
  }

  void _navigateToGroup(GroupModel group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailScreen(group: group),
      ),
    );
  }

  void _navigateToCreateGroup() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
    if (created == true) {
      _loadGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadGroups,
        child: groups.isEmpty
            ? const Center(
                child: Text(
                  'No groups yet.\nTap + to create one!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const Icon(Icons.group, size: 30),
                      title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${group.members.length} members'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () => _navigateToGroup(group),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateGroup,
        tooltip: 'Create New Group',
        child: const Icon(Icons.group_add),
      ),
    );
  }
}