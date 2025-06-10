// lib/models/group_model.dart

class GroupModel {
  final String id;
  final String name;
  final List<String> members; // List of player names or user IDs
  final List<String> gameIds; // IDs of games played in this group

  GroupModel({
    required this.id,
    required this.name,
    required this.members,
    required this.gameIds,
  });

  // Convert to Map for storage (e.g., in local DB or Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'members': members,
      'gameIds': gameIds,
    };
  }

  // Create GroupModel from a Map
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'],
      name: map['name'],
      members: List<String>.from(map['members']),
      gameIds: List<String>.from(map['gameIds']),
    );
  }
}