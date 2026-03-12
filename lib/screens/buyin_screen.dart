import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class BuyInScreen extends StatefulWidget {
  const BuyInScreen({super.key});

  @override
  State<BuyInScreen> createState() => _BuyInScreenState();
}

class _BuyInScreenState extends State<BuyInScreen> {
  List<Map<String, dynamic>> players = [];
  late double chipValue;
  late double cashValue;
  String? groupName;
  String? roomName;

  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _newNameController = TextEditingController();
  final TextEditingController _newBuyInController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    if (args == null) {
      // Handle the case where arguments are null
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Missing game data. Please restart the game.'),
          ),
        );
        Navigator.pop(context);
      });
      return;
    }
    if (players.isEmpty) {
      // Avoid reinitialization
      players = List<Map<String, dynamic>>.from(args['players'] ?? []);
    }
    chipValue = args['chipValue'] ?? 0.0;
    cashValue = args['cashValue'] ?? 0.0;
    groupName = args['groupName']; // optional
    roomName = args['roomName']; // optional

    for (final player in players) {
      if (!_controllers.containsKey(player['name'])) {
        _controllers[player['name']] = TextEditingController();
      }
    }
  }

  void _addBuyIn(String name, double amount) {
    final player = players.firstWhere((p) => p['name'] == name);
    setState(() {
      player['buyIn'] += amount;
    });
    _controllers[name]!.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ₹${amount.toInt()} to $name')),
    );
  }

  void _addNewPlayer() {
    final name = _newNameController.text.trim();
    final buyIn = double.tryParse(_newBuyInController.text.trim());
    if (name.isEmpty || buyIn == null || buyIn <= 0) return;

    setState(() {
      players.add({'name': name, 'buyIn': buyIn});
      _controllers[name] = TextEditingController();
    });

    _newNameController.clear();
    _newBuyInController.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Added new player $name')));
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _newNameController.dispose();
    _newBuyInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mid-Game Buy-Ins'),
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
                  'Add Buy-In for Players',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage current session stakes',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 24),

                ...players.map((player) {
                  final name = player['name'];
                  final current = player['buyIn'];
                  final isHost = player['isHost'] == true;
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
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
                                    'Current Buy-In: ₹${current.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              CircleAvatar(
                                radius: 18,
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
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: TextField(
                                    controller: _controllers[name],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      prefixIcon: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          '₹',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      prefixIconConstraints:
                                          const BoxConstraints(
                                            minWidth: 0,
                                            minHeight: 0,
                                          ),
                                      hintText: 'Add Buy-In',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 0,
                                            horizontal: 16,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () {
                                    final value = double.tryParse(
                                      _controllers[name]!.text.trim(),
                                    );
                                    if (value != null && value > 0) {
                                      _addBuyIn(name, value);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  child: const Text('Add'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFF2D2D38)),
                const SizedBox(height: 24),

                Row(
                  children: [
                    const Icon(
                      Icons.person_add_alt_1,
                      color: Color(0xFF8B5CF6),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Add New Player',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141419),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D2D38)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PLAYER NAME',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _newNameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Rachel Green',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'BUY-IN (₹)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _newBuyInController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixIcon: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '₹',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          hintText: '500',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addNewPlayer,
                        icon: const Icon(Icons.add_circle, size: 20),
                        label: const Text('Add Player'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/result',
                  arguments: {
                    'players': players,
                    'chipValue': chipValue,
                    'cashValue': cashValue,
                    if (groupName != null) 'groupName': groupName,
                    if (roomName != null) 'roomName': roomName,
                  },
                );
              },
              icon:
                  const SizedBox.shrink(), // No icon in this button per screenshot, only text right-aligned arrow?
              // The screenshot shows "Enter Final Chips >"
              label: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Enter Final Chips'),
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
