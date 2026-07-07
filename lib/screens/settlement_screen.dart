import 'package:flutter/material.dart';

import '../services/draft_session_service.dart';
import '../services/settlement_service.dart';
import '../services/progress_service.dart';
import '../services/user_service.dart';
import '../models/settlement_model.dart';

class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key});

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  List<Map<String, dynamic>> players = [];
  double chipValue = 0;
  double cashValue = 0;
  String? groupName;
  late List<SettlementModel> results;
  late List<String> transactions;
  String? roomName;
  bool _initialized = false;
  final _progressService = ProgressService();
  final _userService = UserService();
  final _draftService = DraftSessionService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    players = List<Map<String, dynamic>>.from(args['players']);
    chipValue = args['chipValue'];
    cashValue = args['cashValue'];
    groupName = args['groupName'];
    roomName = args['roomName'];

    final double ratio = chipValue / cashValue;
    final settlementService = SettlementService();

    results = settlementService.calculateSettlements(
      players: players,
      chipToCashRatio: ratio,
    );

    transactions = settlementService.getSettlementTransactions(results);
    _recordGame();
    _initialized = true;
  }

  Future<void> _recordGame() async {
    // recordGame() returns the UUID used for the poker-split Firestore document.
    // We reuse this same ID for saveSession() so the host's sessions subcollection
    // uses an identical key — this ensures syncMySessions() deduplication works
    // correctly for all linked players.
    final gameId = await _progressService.recordGame(
      chipValue: chipValue,
      cashValue: cashValue,
      settlements: results,
      players: players,
      groupName: groupName,
      roomName: roomName,
    );

    await _userService.saveSession(
      sessionId: gameId,
      roomName: roomName,
      players: players,
      settlements: results,
      chipValue: chipValue,
      cashValue: cashValue,
    );

    // Draft is no longer needed — the game is fully settled and saved.
    await _draftService.clearDraft();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlement Summary'),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.share), onPressed: () {})],
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
                  'Final Summary',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Game session ended at ${TimeOfDay.now().format(context)} • ${players.length} Players',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                ...results.map((r) {
                  // Find original player data to get code and avatarColor
                  final playerData = players.firstWhere(
                    (p) => p['name'] == r.name,
                    orElse: () => <String, dynamic>{},
                  );
                  final isHost = playerData['isHost'] == true;
                  final String codeStr = playerData['code'] ?? '';
                  final String displayName = codeStr.isNotEmpty
                      ? '${r.name} ($codeStr)'
                      : (isHost ? r.name : '${r.name} (Guest)');

                  final String initials = r.name.length > 1
                      ? r.name.substring(0, 2).toUpperCase()
                      : r.name.toUpperCase();
                  final netText = r.netProfit > 0
                      ? '+₹${r.netProfit.toStringAsFixed(0)}'
                      : '-₹${r.netProfit.abs().toStringAsFixed(0)}';
                  final netColor = r.netProfit >= 0
                      ? const Color(0xFF10B981) // Neon Green
                      : const Color(0xFFEF4444); // Neon Red

                  // Avatar styling
                  Color avatarBg = const Color(0xFF2D2D38);
                  Color avatarTc = Colors.white70;
                  if (playerData['avatarColor'] != null) {
                    avatarBg = Color(int.parse(playerData['avatarColor']));
                    avatarTc = Colors.white;
                  } else if (isHost) {
                    avatarBg = const Color(0xFF8B5CF6).withOpacity(0.2);
                    avatarTc = const Color(0xFF8B5CF6);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181E),
                      borderRadius: BorderRadius.circular(24),
                      border: const Border(
                        top: BorderSide.none,
                        right: BorderSide.none,
                        bottom: BorderSide.none,
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: [
                        // Colored left border simulation using a thin container
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(width: 3, color: netColor),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
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
                                      'Buy-In: ₹${r.buyIn.toStringAsFixed(0)} • Final: ₹${r.finalAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                netText,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: netColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                _ToggleableSettlement(transactions: transactions),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                minimumSize: const Size.fromHeight(56),
              ),
              child: const Text(
                'Close Game & Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleableSettlement extends StatefulWidget {
  final List<String> transactions;

  const _ToggleableSettlement({required this.transactions});

  @override
  State<_ToggleableSettlement> createState() => _ToggleableSettlementState();
}

class _ToggleableSettlementState extends State<_ToggleableSettlement> {
  bool showTransactions = true; // Default to showing per mockup

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Who Owes Whom',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  showTransactions = !showTransactions;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      showTransactions
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFF8B5CF6),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      showTransactions ? 'Hide' : 'Show',
                      style: const TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (showTransactions)
          ...widget.transactions.map((t) {
            // Very simple parser to bold names based on standard string format (e.g. "Sarah pays ₹150 to Mike")
            // This assumes getSettlementTransactions() returns "Name pays ₹Amount to Name"

            // To mimic the exact dark card layout with purple icon
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFF2D2D38), width: 1),
              ),
              color: const Color(0xFF141419),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                      child: const Icon(
                        Icons.compare_arrows,
                        color: Color(0xFF8B5CF6),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        t,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Per request: "dont add pay button and its functionality"
                    // Omitting the "Pay" button from mockup
                  ],
                ),
              ),
            );
          }),
        if (showTransactions && widget.transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Everything is settled! No payments required.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
      ],
    );
  }
}
