import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const List<String> avatarColors = [
    '0xFFEF4444', // Red
    '0xFFF97316', // Orange
    '0xFFF59E0B', // Amber
    '0xFF10B981', // Green
    '0xFF06B6D4', // Cyan
    '0xFF3B82F6', // Blue
    '0xFF8B5CF6', // Purple
    '0xFFD946EF', // Fuchsia
    '0xFFEC4899', // Pink
  ];

  /// Generates a random 6-character uppercase alphanumeric code.
  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      6,
      (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }

  /// Ensures current user has a profile in `users/`. Returns true if a new code was generated.
  Future<bool> getOrCreateUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final docRef = _db.collection('users').doc(user.uid);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      return false; // User already exists
    }

    // Need to generate a new unique code
    String newCode = '';
    bool isUnique = false;

    while (!isUnique) {
      newCode = _generateCode();
      final query = await _db.collection('users').where('code', isEqualTo: newCode).get();
      if (query.docs.isEmpty) {
        isUnique = true;
      }
    }

    // Pick a random color
    final randomColor = avatarColors[Random().nextInt(avatarColors.length)];

    await docRef.set({
      'displayName': user.displayName ?? 'Player',
      'code': newCode,
      'nameChangeUsed': false,
      'avatarColor': randomColor,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return true; // Indicates a new code was generated
  }

  /// Fetch user profile data stream
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfileStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db.collection('users').doc(user.uid).snapshots();
  }

  /// Updates display name (can only be done once)
  Future<void> updateDisplayName(String newName) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    await _db.collection('users').doc(user.uid).update({
      'displayName': newName.trim(),
      'nameChangeUsed': true,
    });
  }

  /// Updates avatar color
  Future<void> updateAvatarColor(String colorHex) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    await _db.collection('users').doc(user.uid).update({
      'avatarColor': colorHex,
    });
  }

  /// Look up a user by exactly 6-character code
  Future<Map<String, dynamic>?> getUserByCode(String code) async {
    if (code.length != 6) return null;
    
    final query = await _db.collection('users').where('code', isEqualTo: code.toUpperCase()).get();
    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      data['uid'] = query.docs.first.id;
      return data;
    }
    return null;
  }

  /// Fetches total number of games played by this user via sessions subcollection count
  Future<int> getTotalGamesCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    
    final query = await _db.collection('users').doc(user.uid).collection('sessions').count().get();
    return query.count ?? 0;
  }

  /// Saves a session summary to Firestore for each linked player (those with a userId).
  /// Called from SettlementScreen after settlement is calculated.
  Future<void> saveSession({
    required String sessionId,
    required String? roomName,
    required List<Map<String, dynamic>> players,
    required List<dynamic> settlements, // List of SettlementModel
    required double chipValue,
    required double cashValue,
  }) async {
    final now = FieldValue.serverTimestamp();

    // Build a compact names list for display in Recent Games cards
    final allPlayerNames = players.map((p) => p['name'] as String).toList();
    final playerCount = players.length;

    for (final player in players) {
      final String? uid = player['userId'];
      if (uid == null) continue; // Skip unlinked (guest) players

      // Find this player's settlement result
      final settlement = settlements.firstWhere(
        (s) => s.name == player['name'],
        orElse: () => null,
      );

      if (settlement == null) continue;

      final sessionData = {
        'sessionId': sessionId,
        'roomName': roomName?.isNotEmpty == true ? roomName : 'Untitled Game',
        'date': now,
        'playerName': player['name'],
        'playerCode': player['code'] ?? '',
        'buyIn': player['buyIn'],
        'cashOut': settlement.finalAmount,
        'net': settlement.netProfit,
        'chipValue': chipValue,
        'cashValue': cashValue,
        'playerCount': playerCount,
        'playerNames': allPlayerNames,
      };

      await _db
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .doc(sessionId)
          .set(sessionData);
    }
  }

  /// Loads all sessions for the current user from Firestore, sorted by date descending.
  /// These sessions exist for any game where the user was linked via their code.
  Future<List<Map<String, dynamic>>> loadUserSessions() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final query = await _db
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .orderBy('date', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        // Convert Firestore Timestamp to DateTime for easier use
        final ts = data['date'];
        return {
          ...data,
          'date': ts is Timestamp ? ts.toDate() : DateTime.now(),
          'sessionId': doc.id,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
