import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:myapp/services/auth_service.dart';
import '../services/progress_service.dart';
import '../services/user_service.dart';
import 'package:intl/intl.dart';
import 'performance_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Moved widgetOptions here to pass the callback
    final List<Widget> widgetOptions = <Widget>[
      HomeTab(onViewAll: () => _onItemTapped(2)),
      const Scaffold(
        body: Center(child: Text('Games Tab (Coming Soon)')),
      ), // Placeholder for Games
      const PerformanceScreen(),
      const ProfileScreen(), // Replaces Settings
    ];

    return Scaffold(
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'HOME'),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports),
            label: 'GAMES',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'ANALYTICS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'PROFILE',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  final VoidCallback onViewAll;

  const HomeTab({super.key, required this.onViewAll});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final AuthService authService = AuthService();
  final UserService userService = UserService();
  List<Map<String, dynamic>> _recentGames = [];
  bool _isLoading = true;
  String? _myCode;
  String _displayName = 'Player';

  @override
  void initState() {
    super.initState();
    _initProfile();
    _loadRecentGames();
  }

  Future<void> _initProfile() async {
    final isNewCode = await userService.getOrCreateUser();
    
    // Fetch code and displayName from Firestore (source of truth)
    userService.getUserProfileStream().listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          _myCode = snapshot.data()?['code'];
          _displayName = snapshot.data()?['displayName'] ?? 'Player';
        });

        if (isNewCode) {
          _showOnboardingSheet(_myCode!);
        }
      }
    });
  }

  void _showOnboardingSheet(String code) {
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, color: Color(0xFF8B5CF6), size: 48),
              const SizedBox(height: 16),
              Text(
                'Your Player Code is $code',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Share this code with friends so they can add you to games instantly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
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
                        fontSize: 28,
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
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadRecentGames() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    // PRIMARY: Firestore sessions (cross-device for linked players)
    final firestoreSessions = await userService.loadUserSessions();
    // Already sorted descending by date from Firestore query

    // FALLBACK: Local games for host sessions not yet in Firestore
    final firestoreSessionIds = firestoreSessions.map((s) => s['sessionId'] as String).toSet();
    final localGames = await ProgressService().loadGames();

    final localOnly = <Map<String, dynamic>>[];
    for (final game in localGames) {
      final participated = game.results.any(
        (p) => p.userId == user.uid || (user.email != null && p.email == user.email),
      );
      if (!participated) continue;
      if (firestoreSessionIds.contains(game.id)) continue;

      final myResult = game.results.firstWhere(
        (p) => p.userId == user.uid || (user.email != null && p.email == user.email),
      );
      localOnly.add({
        'sessionId': game.id,
        'roomName': game.roomName,
        'date': game.createdAt,
        'net': myResult.netProfit,
        'playerCount': game.results.length,
      });
    }

    // Merge and sort all sessions descending by date
    final allSessions = [...firestoreSessions, ...localOnly];
    allSessions.sort((a, b) {
      final da = a['date'];
      final db = b['date'];
      if (da is DateTime && db is DateTime) return db.compareTo(da);
      return 0;
    });

    final topSessions = allSessions.take(3).toList();

    final formattedGames = topSessions.map((s) {
      final date = s['date'];
      final dateStr = date is DateTime
          ? DateFormat('MMM dd, yyyy').format(date)
          : '';
      return {
        'title': s['roomName'] ?? 'Untitled Game',
        'date': dateStr,
        'players': s['playerCount'] ?? 0,
        'profit': ((s['net'] as num?)?.toDouble() ?? 0.0).round(),
        'icon': Icons.style,
      };
    }).toList();

    if (!mounted) return;
    setState(() {
      _recentGames = formattedGames;
      _isLoading = false;
    });
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PokerPal 🃏'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome, $_displayName! 👋',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            if (_myCode != null)
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    // Navigate to Profile tab (index 3)
                    // We can't easily push bottom nav index from child without callbacks, 
                    // but since this is inside HomeTab we can just copy to clipboard for now as a quick action.
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'My Code: $_myCode',
                          style: const TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _myCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied!')),
                            );
                          },
                          child: const Icon(Icons.copy, size: 14, color: Color(0xFF8B5CF6)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              "Ready for tonight's session?",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                '/game',
              ).then((_) => _loadRecentGames()),
              icon: const Icon(Icons.add_circle, size: 20),
              label: const Text('Start New Game'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/groups'),
              icon: const Icon(Icons.group, size: 20),
              label: const Text('Play with your Group'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Games',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: widget.onViewAll,
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),

            if (!_isLoading && _recentGames.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    "No games yet! Tap 'Start New Game' to begin.",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),

            if (!_isLoading && _recentGames.isNotEmpty)
              ..._recentGames.map(
                (gameData) => _buildRecentGameCard(
                  icon: gameData['icon'],
                  title: gameData['title'],
                  date: gameData['date'],
                  players: gameData['players'],
                  profit: gameData['profit'],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentGameCard({
    required IconData icon,
    required String title,
    required String date,
    required int players,
    required int profit,
  }) {
    final bool isPositive = profit > 0;
    final bool isZero = profit == 0;
    final Color profitColor = isPositive
        ? const Color(0xFF10B981)
        : (isZero ? Colors.grey : const Color(0xFFEF4444));

    final String profitTextRupee = isPositive
        ? '+₹$profit'
        : (isZero ? '₹0' : '-₹${profit.abs()}');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2D2D38), width: 1),
      ),
      elevation: 0,
      color: const Color(
        0xFF141419,
      ), // Slightly darker card matched to recent games screenshot
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF8B5CF6), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'Unnamed Room' : title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$date  •  $players Players',
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
            Text(
              profitTextRupee,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: profitColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
