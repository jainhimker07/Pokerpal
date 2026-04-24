import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'dart:developer' as dev;

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
      'displayName': 'Player', // Always default to Player — user sets their own name
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

  /// Look up a user by exactly 6-character alphanumeric code.
  /// SECURITY: Only returns public-safe fields (displayName, code, avatarColor).
  /// Never returns uid, email, createdAt or any other private field.
  /// The internal uid is stored under '_resolvedUid' for caller use within the app only.
  Future<Map<String, dynamic>?> getUserByCode(String code) async {
    final sanitised = code.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (sanitised.length != 6) return null;

    final query = await _db.collection('users').where('code', isEqualTo: sanitised).get();
    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final data = doc.data();
      // Return ONLY safe public fields — uid and email are intentionally excluded
      return {
        'displayName': data['displayName'] ?? 'Player',
        'code': data['code'] ?? sanitised,
        'avatarColor': data['avatarColor'],
        '_resolvedUid': doc.id, // Prefixed with _ to signal internal use only
      };
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

  /// Saves the HOST's own session to Firestore. Only writes to the current user's
  /// own path — cross-user writes are blocked by Firestore rules and handled
  /// by syncMySessions() on each player's device instead.
  Future<void> saveSession({
    required String sessionId,
    required String? roomName,
    required List<Map<String, dynamic>> players,
    required List<dynamic> settlements, // List of SettlementModel
    required double chipValue,
    required double cashValue,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final allPlayerNames = players.map((p) => p['name'] as String).toList();
    final playerCount = players.length;

    // Find the current user's own player entry
    final myPlayer = players.firstWhere(
      (p) => p['userId'] == currentUser.uid,
      orElse: () => <String, dynamic>{},
    );
    if (myPlayer.isEmpty) return; // Host didn't tap "Add Me" — nothing to save

    final mySettlement = settlements.firstWhere(
      (s) => s.name == myPlayer['name'],
      orElse: () => null,
    );
    if (mySettlement == null) return;

    await _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('sessions')
        .doc(sessionId)
        .set({
          'sessionId': sessionId,
          'roomName': roomName?.isNotEmpty == true ? roomName : 'Untitled Game',
          'date': FieldValue.serverTimestamp(),
          'playerName': myPlayer['name'],
          'playerCode': myPlayer['code'] ?? '',
          'buyIn': myPlayer['buyIn'],
          'cashOut': mySettlement.finalAmount,
          'net': mySettlement.netProfit,
          'chipValue': chipValue,
          'cashValue': cashValue,
          'playerCount': playerCount,
          'playerNames': allPlayerNames,
        });
  }

  /// Syncs sessions from the shared `poker-split` collection into the current
  /// user's own `users/{uid}/sessions/` subcollection.
  ///
  /// This is the fix for cross-device history: the host writes to poker-split
  /// with all players' UIDs. Each player calls this on app open to claim their
  /// own records without needing cross-user Firestore write access.
  Future<void> syncMySessions() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Find all games in poker-split where this user's uid is in the linkedUids array
      final gamesQuery = await _db
          .collection('poker-split')
          .where('linkedUids', arrayContains: user.uid)
          .get();

      if (gamesQuery.docs.isEmpty) return;

      // Fetch already-synced session IDs to avoid duplicate writes
      final existingSessionsQuery = await _db
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .get();
      final existingIds = existingSessionsQuery.docs.map((d) => d.id).toSet();

      for (final gameDoc in gamesQuery.docs) {
        final gameId = gameDoc.id;
        if (existingIds.contains(gameId)) continue; // Already synced

        final game = gameDoc.data();
        final List<dynamic> gamePlayers = game['players'] ?? [];

        // Find this user's entry in the players array
        final myEntry = gamePlayers.firstWhere(
          (p) => p is Map && p['uid'] == user.uid,
          orElse: () => null,
        );
        if (myEntry == null) continue;

        final date = game['date'];
        final allNames = gamePlayers
            .whereType<Map>()
            .map((p) => p['name']?.toString() ?? '')
            .toList();

        // Write session to the user's own path — allowed by Firestore rules
        await _db
            .collection('users')
            .doc(user.uid)
            .collection('sessions')
            .doc(gameId)
            .set({
              'sessionId': gameId,
              'roomName': game['roomName'] ?? 'Untitled Game',
              'date': date is Timestamp ? date : FieldValue.serverTimestamp(),
              'playerName': myEntry['name'] ?? '',
              'playerCode': myEntry['code'] ?? '',
              'buyIn': (myEntry['buyIn'] as num?)?.toDouble() ?? 0.0,
              'cashOut': (myEntry['cashOut'] as num?)?.toDouble() ?? 0.0,
              'net': (myEntry['net'] as num?)?.toDouble() ?? 0.0,
              'chipValue': (game['chipValue'] as num?)?.toDouble() ?? 1.0,
              'cashValue': (game['cashValue'] as num?)?.toDouble() ?? 1.0,
              'playerCount': gamePlayers.length,
              'playerNames': allNames,
            });
      }
    } catch (e, st) {
      // Log the error so we can debug if sync fails for other players
      dev.log('syncMySessions error: $e', name: 'UserService', error: e, stackTrace: st);
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
    } catch (e, st) {
      dev.log('loadUserSessions error: $e', name: 'UserService', error: e, stackTrace: st);
      return [];
    }
  }
}
