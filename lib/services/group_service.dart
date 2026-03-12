// lib/services/group_service.dart

import '../models/group_model.dart';

class GroupService {
  static final GroupService _instance = GroupService._internal();
  factory GroupService() => _instance;

  GroupService._internal();

  final List<GroupModel> _groups = [];

  List<GroupModel> get groups => List.unmodifiable(_groups);

  void createGroup(
    String id,
    String name,
    List<String> members,
    List<String> gameIds,
  ) {
    final newGroup = GroupModel(
      id: id,
      name: name,
      members: members,
      gameIds: gameIds,
    );
    _groups.add(newGroup);
  }

  void addMember(String groupId, String memberName) {
    final group = _groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => throw Exception('Group not found'),
    );
    if (!group.members.contains(memberName)) {
      group.members.add(memberName);
    }
  }

  GroupModel? getGroupById(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  void deleteGroup(String groupId) {
    _groups.removeWhere((g) => g.id == groupId);
  }

  void clearAllGroups() {
    _groups.clear();
  }

  Future<List<GroupModel>> getAllGroups() async {
    return _groups;
  }
}
