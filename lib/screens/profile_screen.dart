import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  
  bool _isEditingName = false;
  bool _isDeleting = false;
  final TextEditingController _nameController = TextEditingController();

  void _showColorPicker(String currentColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Avatar Color',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: UserService.avatarColors.map((colorHex) {
                    final color = Color(int.parse(colorHex));
                    final isSelected = currentColor == colorHex;
                    return GestureDetector(
                      onTap: () {
                        _userService.updateAvatarColor(colorHex);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _confirmNameChange(String currentName) {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == currentName) {
      setState(() => _isEditingName = false);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C23),
        title: const Text('Confirm Name Change', style: TextStyle(color: Colors.white)),
        content: Text(
          'You can only change your name once. Are you sure you want to set your name to "$newName"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            onPressed: () {
              _userService.updateDisplayName(newName);
              setState(() => _isEditingName = false);
              Navigator.pop(context);
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C23),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _authService.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C23),
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete your account, player code, and all game history. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _executeDeleteAccount();
            },
            child: const Text('Delete My Account', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDeleteAccount() async {
    setState(() => _isDeleting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Pre-emptively reauthenticate to avoid requires-recent-login mid-flow
      final reauthed = await _authService.reauthenticate();
      if (!reauthed) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please verify your identity to delete your account')),
        );
        setState(() => _isDeleting = false);
        return;
      }

      final db = FirebaseFirestore.instance;

      // 1. Delete all documents in users/{uid}/sessions/ subcollection
      final sessionsQuery = await db.collection('users').doc(user.uid).collection('sessions').get();
      final docs = sessionsQuery.docs;
      for (var i = 0; i < docs.length; i += 500) {
        final batch = db.batch();
        final end = (i + 500 < docs.length) ? i + 500 : docs.length;
        for (final doc in docs.sublist(i, end)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // 2. Delete the users/{uid} document
      await db.collection('users').doc(user.uid).delete();

      // 3. Delete the Firebase Auth account
      await user.delete();

      // 4. Navigate to login and clear the navigation stack
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while deleting your account')),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: false,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userService.getUserProfileStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Profile not found', style: TextStyle(color: Colors.white54)));
          }

          final data = snapshot.data!.data()!;
          final displayName = data['displayName'] ?? 'Player';
          final code = data['code'] ?? '------';
          final nameChangeUsed = data['nameChangeUsed'] ?? false;
          final avatarColorHex = data['avatarColor'] ?? UserService.avatarColors.first;
          final avatarColor = Color(int.parse(avatarColorHex));
          
          final initials = displayName.length > 1 
              ? displayName.substring(0, 2).toUpperCase() 
              : displayName.toUpperCase();

          if (!_isEditingName) {
            _nameController.text = displayName;
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // 1. Avatar Circle
              Center(
                child: GestureDetector(
                  onTap: () => _showColorPicker(avatarColorHex),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: avatarColor,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2D2D38),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.palette, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // 2. Display Name
              const Text(
                'DISPLAY NAME',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 8),
              if (nameChangeUsed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141419),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D2D38)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const Icon(Icons.lock, size: 18, color: Colors.white54),
                    ],
                  ),
                )
              else if (!_isEditingName)
                GestureDetector(
                  onTap: () => setState(() => _isEditingName = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141419),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2D2D38)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        const Icon(Icons.edit, size: 18, color: Color(0xFF8B5CF6)),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter new name',
                          fillColor: const Color(0xFF141419),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onPressed: () => _confirmNameChange(displayName),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                  ],
                ),
              
              const SizedBox(height: 8),
              const Text(
                'Name can only be changed once',
                style: TextStyle(fontSize: 12, color: Colors.white38),
              ),
              const SizedBox(height: 32),

              // 3. Player Code
              const Text(
                'YOUR PLAYER CODE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Color(0xFF8B5CF6)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share this with friends to link you in their games',
                style: TextStyle(fontSize: 12, color: Colors.white38),
              ),
              const SizedBox(height: 48),

              // 4. Stats Teaser
              GestureDetector(
                onTap: () {
                  // Navigate to Performance tab - assuming it's index 2 on Home's BottomNav
                  // This is a simple pop back to home if pushed, or handled by a callback.
                  // Since we are inside the BottomNav, we might need a callback, or
                  // just push named route to home with arguments, or simplest: keep it visual only
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141419),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF2D2D38)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL GAMES PLAYED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<int>(
                            future: _userService.getTotalGamesCount(),
                            builder: (context, statsSnap) {
                              return Text(
                                '${statsSnap.data ?? 0}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white54),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // 5. Sign Out
              OutlinedButton.icon(
                onPressed: _confirmSignOut,
                icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                label: const Text('Sign Out', style: TextStyle(color: Color(0xFFEF4444))),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),

              // 6. Delete Account
              OutlinedButton.icon(
                onPressed: _isDeleting ? null : _confirmDeleteAccount,
                icon: _isDeleting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFEF4444), strokeWidth: 2))
                    : const Icon(Icons.delete_forever, color: Color(0xFFEF4444)),
                label: Text(_isDeleting ? 'Deleting...' : 'Delete Account', style: const TextStyle(color: Color(0xFFEF4444))),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}
