import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/user_service.dart';
import '../services/draft_session_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _chipController = TextEditingController();
  final TextEditingController _cashController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _buyInController = TextEditingController();
  final TextEditingController _roomNameController = TextEditingController();

  final UserService _userService = UserService();
  final DraftSessionService _draftService = DraftSessionService();
  Timer? _debounce;
  bool _isCodeSearching = false;
  bool _isCodeValid = false;
  String? _linkedUid; // Internal uid from _resolvedUid — never from getUserByCode's 'uid' field
  String? _linkedAvatarColorHex;

  List<Map<String, dynamic>> players = [];
  String? groupName;
  bool isGroupGame = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      if (args.containsKey('groupName')) {
        groupName = args['groupName'];
        isGroupGame = true;
      }
      if (args.containsKey('players')) {
        players = List<Map<String, dynamic>>.from(args['players']);
      }
      // Restore chip/cash ratio if navigating back from a draft restore
      if (args.containsKey('chipValue')) {
        _chipController.text = args['chipValue'].toString();
      }
      if (args.containsKey('cashValue')) {
        _cashController.text = args['cashValue'].toString();
      }
      if (args.containsKey('roomName') && args['roomName'] != null) {
        _roomNameController.text = args['roomName'] as String;
      }
      // Persist the restored state immediately
      if (players.isNotEmpty) _saveDraft('game');
    }
  }

  /// Builds the current game-setup state map and saves it as a draft.
  void _saveDraft(String screen) {
    final chip = double.tryParse(_chipController.text.trim()) ?? 0.0;
    final cash = double.tryParse(_cashController.text.trim()) ?? 0.0;
    _draftService.saveDraft({
      'screen': screen,
      'players': players,
      'chipValue': chip,
      'cashValue': cash,
      'roomName': _roomNameController.text.trim(),
      if (groupName != null) 'groupName': groupName,
    });
  }

  void _onCodeChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (value.length != 6) {
      if (_isCodeValid || _isCodeSearching) {
        setState(() {
          _isCodeSearching = false;
          _isCodeValid = false;
          _linkedUid = null;
          _linkedAvatarColorHex = null;
          _nameController.clear();
        });
      }
      return;
    }

    setState(() => _isCodeSearching = true);

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final userData = await _userService.getUserByCode(value);
      if (mounted) {
        setState(() {
          _isCodeSearching = false;
          if (userData != null) {
            _isCodeValid = true;
            _linkedUid = userData['_resolvedUid'] as String?; // Only internal uid key
            _linkedAvatarColorHex = userData['avatarColor'] as String?;
            _nameController.text = userData['displayName'] ?? 'Player';
          } else {
            _isCodeValid = false;
            _linkedUid = null;
            _linkedAvatarColorHex = null;
            _nameController.clear();
          }
        });
      }
    });
  }

  void _continueToGame() {
    final chip = double.tryParse(_chipController.text.trim());
    final cash = double.tryParse(_cashController.text.trim());

    if (players.isEmpty ||
        chip == null ||
        cash == null ||
        chip <= 0 ||
        cash <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid ratio and add players'),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/buyins',
      arguments: {
        'players': players,
        'chipValue': chip,
        'cashValue': cash,
        if (groupName != null) 'groupName': groupName,
        'roomName': _roomNameController.text.trim(),
      },
    );
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    final buyIn = double.tryParse(_buyInController.text.trim());

    if (name.isEmpty || buyIn == null || buyIn <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid player name and buy-in'),
        ),
      );
      return;
    }

    String? userId;
    String? email;
    bool isHost = false;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null &&
        name.toLowerCase() == (currentUser.displayName ?? '').toLowerCase()) {
      userId = currentUser.uid;
      email = currentUser.email;
      isHost = true;
    }

    // Override with linked account if code matched
    // SECURITY: _linkedUid comes from _resolvedUid returned by getUserByCode.
    // Email is NOT stored from code lookup — it is only set for the host via FirebaseAuth.
    if (_linkedUid != null) {
      userId = _linkedUid;
      email = null; // Email from code lookup is intentionally blocked
      isHost = false;
    }

    players.add({
      'name': name,
      'buyIn': buyIn,
      if (userId != null) 'userId': userId,
      if (email != null) 'email': email,
      'isHost': isHost,
      if (_codeController.text.length == 6 && _isCodeValid) 'code': _codeController.text.toUpperCase(),
      if (_linkedAvatarColorHex != null) 'avatarColor': _linkedAvatarColorHex,
    });
    _nameController.clear();
    _codeController.clear();
    _buyInController.clear();
    setState(() {
      _isCodeValid = false;
      _linkedUid = null;
      _linkedAvatarColorHex = null;
    });
    _saveDraft('game');
  }

  @override
  void dispose() {
    _chipController.dispose();
    _cashController.dispose();
    _nameController.dispose();
    _buyInController.dispose();
    _roomNameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double totalBuyIn = players.fold(
      0.0,
      (sum, player) => sum + (player['buyIn'] as double),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Game'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
        bottom: groupName != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Group: $groupName',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 100,
              ), // padding for fixed button
              children: [
                const Text(
                  'ROOM NAME (Optional)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _roomNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Friday Night Poker',
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'CHIP-TO-CASH RATIO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chips',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _chipController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '1000'),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        '=',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cash (₹)',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _cashController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '100'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                if (FirebaseAuth.instance.currentUser != null &&
                    !players.any(
                      (p) =>
                          p['userId'] == FirebaseAuth.instance.currentUser!.uid,
                    ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        // Fetch Firestore profile first
                        final snapshot = await _userService.getUserProfileStream().first;
                        final data = snapshot.data();
                        final myCode = data?['code'] ?? '';
                        final myColor = data?['avatarColor'];
                        final myName = data?['displayName'] ?? user.displayName ?? 'Me';

                        if (!mounted) return;

                        // Show buy-in dialog
                        final buyInController = TextEditingController();
                        final confirmed = await showDialog<double>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            backgroundColor: const Color(0xFF1C1C23),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            title: const Text(
                              'Your Initial Buy-In',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            content: TextField(
                              controller: buyInController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              autofocus: true,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Buy-In Amount (₹)',
                                labelStyle: const TextStyle(color: Colors.white54),
                                prefixText: '₹ ',
                                prefixStyle: const TextStyle(color: Colors.white54),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFF2D2D38)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF141419),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B5CF6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  final amount = double.tryParse(buyInController.text.trim());
                                  if (amount != null && amount > 0) {
                                    Navigator.pop(dialogContext, amount);
                                  }
                                },
                                child: const Text('Add Me', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == null || !mounted) return;

                        setState(() {
                          players.insert(0, {
                            'name': myName,
                            'buyIn': confirmed,
                            'userId': user.uid,
                            'email': user.email,
                            'isHost': true,
                            if (myCode.isNotEmpty) 'code': myCode,
                            if (myColor != null) 'avatarColor': myColor,
                          });
                        });
                        _saveDraft('game');
                      },

                      icon: const Icon(Icons.person),
                      label: const Text('Add Me (Link to Stats)'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                    ),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ADD PLAYER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white54,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Quick Add',
                        style: TextStyle(
                          color: Color(0xFF8B5CF6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 35,
                      child: TextField(
                        controller: _codeController,
                        onChanged: _onCodeChanged,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 6,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        buildCounter: (_, {required currentLength, required isFocused, required maxLength}) => null,
                        inputFormatters: [
                          // Only allow A-Z and 0-9 — no special chars or spaces
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                          TextInputFormatter.withFunction((old, newVal) =>
                            newVal.copyWith(text: newVal.text.toUpperCase())),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Code (opt)',
                          suffixIcon: _isCodeSearching 
                            ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                            : _isCodeValid && _codeController.text.length == 6
                                ? const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18)
                                : !_isCodeValid && _codeController.text.length == 6
                                    ? const Icon(Icons.error, color: Color(0xFFEF4444), size: 18)
                                    : null,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _codeController.text.length == 6 
                                ? (_isCodeValid ? const Color(0xFF10B981) : const Color(0xFFEF4444)) 
                                : const Color(0xFF2D2D38),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _codeController.text.length == 6 
                                ? (_isCodeValid ? const Color(0xFF10B981) : const Color(0xFFEF4444)) 
                                : const Color(0xFF8B5CF6),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 65,
                      child: TextField(
                        controller: _nameController,
                        readOnly: _isCodeValid,
                        maxLength: 30,
                        buildCounter: (_, {required currentLength, required isFocused, required maxLength}) => null,
                        style: TextStyle(color: _isCodeValid ? Colors.white54 : Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Player Name',
                          fillColor: _isCodeValid ? const Color(0xFF1C1C23) : const Color(0xFF141419),
                          filled: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _buyInController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Initial Buy-In (₹)',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addPlayer,
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text('Add Player'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Active Players (${players.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Total Buy-In: ₹${totalBuyIn.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ...players.map((player) {
                  final isHost = player['isHost'] == true;
                  final String name = player['name'];
                  final String codeStr = player['code'] ?? '';
                  final String displayName = codeStr.isNotEmpty ? '$name ($codeStr)' : (isHost ? name : '$name (Guest)');
                  
                  final String initials = name.length > 1
                      ? name.substring(0, 2).toUpperCase()
                      : name.toUpperCase();
                  
                  // Use specific avatar color if linked, otherwise host styling or guest styling
                  Color avatarBg = const Color(0xFF2D2D38);
                  Color avatarTc = Colors.white;
                  
                  if (player['avatarColor'] != null) {
                    avatarBg = Color(int.parse(player['avatarColor']));
                  } else if (isHost) {
                    avatarBg = const Color(0xFF8B5CF6).withOpacity(0.2);
                    avatarTc = const Color(0xFF8B5CF6);
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: Color(0xFF2D2D38),
                        width: 1,
                      ),
                    ),
                    color: const Color(0xFF141419),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: avatarBg,
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: avatarTc,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isHost ? 'Host' : 'Guest',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${player['buyIn']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'BUY-IN',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: ElevatedButton.icon(
              onPressed: _continueToGame,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Continue to Game'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
