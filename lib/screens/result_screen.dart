import 'package:flutter/material.dart';
import '../services/draft_session_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late List<Map<String, dynamic>> players;
  late double chipValue;
  late double cashValue;
  String? groupName;
  String? roomName;
  final Map<String, TextEditingController> _controllers = {};
  final DraftSessionService _draftService = DraftSessionService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    players = List<Map<String, dynamic>>.from(args['players']);
    chipValue = args['chipValue'];
    cashValue = args['cashValue'];
    groupName = args['groupName'];
    roomName = args['roomName'];

    for (final player in players) {
      _controllers[player['name']] = TextEditingController();
    }
    // Persist that we are now on the result screen (draft-restore path)
    _saveDraft();
  }

  /// Persists the current chip-entry state as a draft.
  void _saveDraft() {
    _draftService.saveDraft({
      'screen': 'result',
      'players': players,
      'chipValue': chipValue,
      'cashValue': cashValue,
      'roomName': roomName,
      if (groupName != null) 'groupName': groupName,
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double ratio = chipValue / cashValue;

    // Calculate total buy-in in chips
    final double totalChipBuyIn = players.fold(
      0.0,
      (sum, p) => sum + ((p['buyIn'] as double) * ratio),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Final Chips'),
        centerTitle: true,
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
              ),
              children: [
                const Text(
                  'Final Chip Counts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total Expected Chips: ${totalChipBuyIn.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 24),

                ...players.map((player) {
                  final String name = player['name'];
                  final String initials = name.length > 1
                      ? name.substring(0, 2).toUpperCase()
                      : name.toUpperCase();
                  final isHost = player['isHost'] == true;
                  final String codeStr = player['code'] ?? '';
                  final String displayName = codeStr.isNotEmpty ? '$name ($codeStr)' : (isHost ? name : '$name (Guest)');

                  // Avatar styling
                  Color avatarBg = const Color(0xFF2D2D38);
                  Color avatarTc = Colors.white;
                  if (player['avatarColor'] != null) {
                    avatarBg = Color(int.parse(player['avatarColor']));
                  } else if (isHost) {
                    avatarBg = const Color(0xFF8B5CF6).withOpacity(0.2);
                    avatarTc = const Color(0xFF8B5CF6);
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
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
                            radius: 20,
                            backgroundColor: avatarBg,
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: avatarTc,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
                                  'Buy-In: ₹${player['buyIn']}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            height: 48,
                            child: TextField(
                              controller: _controllers[name],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: 'Chips...',
                                hintStyle: const TextStyle(fontSize: 14),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              onChanged: (value) {
                                player['finalChips'] =
                                    double.tryParse(value) ?? 0;
                                _saveDraft();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: ElevatedButton.icon(
              onPressed: () {
                final double totalFinalChips = players.fold(
                  0.0,
                  (sum, p) => sum + (p['finalChips'] ?? 0),
                );

                if ((totalFinalChips - totalChipBuyIn).abs() > 0.01) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Mismatch! Final chips total (${totalFinalChips.toStringAsFixed(0)}) ≠ Buy-in total (${totalChipBuyIn.toStringAsFixed(0)})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                Navigator.pushNamed(
                  context,
                  '/settlement',
                  arguments: {
                    'players': players,
                    'chipValue': chipValue,
                    'cashValue': cashValue,
                    if (groupName != null) 'groupName': groupName,
                    if (roomName != null) 'roomName': roomName,
                  },
                );
              },
              icon: const SizedBox.shrink(),
              label: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Calculate Settlement'),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 20),
                ],
              ),
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
