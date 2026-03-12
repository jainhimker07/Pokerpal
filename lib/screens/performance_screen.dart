import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/progress_service.dart';
import '../services/performance_service.dart';
import '../services/user_service.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final _progressService = ProgressService();
  final _performanceService = PerformanceService();
  final _userService = UserService();

  bool _isLoading = true;
  PlayerStats? _stats;
  String _filter = 'Last 5'; // Options: Last 5, Last 10, All Time

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    // PRIMARY: Load from Firestore sessions (cross-device, for linked players)
    final firestoreSessions = await _userService.loadUserSessions();

    // FALLBACK: Load local games for unlinked host sessions
    // Convert local GameModel records to session-like maps and merge if not already in Firestore
    final firestoreSessionIds = firestoreSessions.map((s) => s['sessionId'] as String).toSet();
    final localGames = await _progressService.loadGames();
    final localSessions = <Map<String, dynamic>>[];

    for (final game in localGames) {
      // Only include games where this user participated
      final myResult = game.results.cast<dynamic>().where(
        (p) => p.userId == user.uid || (user.email != null && p.email == user.email),
      );
      if (myResult.isEmpty) continue;
      // Skip if already captured in Firestore sessions
      if (firestoreSessionIds.contains(game.id)) continue;

      final result = myResult.first;
      localSessions.add({
        'sessionId': game.id,
        'roomName': game.roomName,
        'date': game.createdAt,
        'net': result.netProfit,
        'buyIn': result.buyIn,
        'cashOut': result.finalAmount,
        'playerCount': game.results.length,
      });
    }

    // Merge: Firestore sessions + unique local-only games
    final allSessions = [...firestoreSessions, ...localSessions];
    final stats = _performanceService.getStatsFromSessions(allSessions);

    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  List<GameHistoryPoint> _getFilteredHistory() {
    if (_stats == null) return [];

    final history = _stats!.gameHistory; // Already sorted by date

    if (_filter == 'Last 5') {
      return history.length > 5 ? history.sublist(history.length - 5) : history;
    } else if (_filter == 'Last 10') {
      return history.length > 10
          ? history.sublist(history.length - 10)
          : history;
    } else if (_filter == 'Last 30 Days') {
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      return history.where((p) => p.date.isAfter(cutoff)).toList();
    }

    return history;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_stats == null || _stats!.totalGames == 0) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Performance'),
          actions: [
            IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No games played yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _loadStats, child: const Text('Refresh')),
            ],
          ),
        ),
      );
    }

    final isProfit = _stats!.totalProfitLoss >= 0;
    final color = isProfit ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final filteredHistory = _getFilteredHistory();

    // Derived stats for the new 2x2 grid design
    final winPercentage = _stats!.totalGames > 0
        ? (_stats!.wins / _stats!.totalGames * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.account_circle, color: Color(0xFF8B5CF6)),
            SizedBox(width: 8),
            Text('Performance'),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // 1. Overall Profit / Loss header
            const SizedBox(height: 12),
            Text(
              isProfit
                  ? '+₹${_stats!.totalProfitLoss.toStringAsFixed(0)}'
                  : '-₹${_stats!.totalProfitLoss.abs().toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'OVERALL PROFIT',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                ),
              ),
              child: Text(
                isProfit ? "You're up overall 🔥" : "You're down overall 📉",
                style: const TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 2. Filter Control
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('Last 5 games', 'Last 5'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Last 10 games', 'Last 10'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Last 30 days', 'Last 30 Days'),
                  const SizedBox(width: 8),
                  _buildFilterChip('All Time', 'All Time'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Time Series Graph Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C23),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'TREND ANALYSIS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.white54,
                        ),
                      ),
                      Text(
                        '+12% vs last period', // Hardcoded mockup text to match design functionality missing from data model
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 140,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1000,
                          getDrawingHorizontalLine: (value) =>
                              FlLine(color: Colors.white10, strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 &&
                                    index < filteredHistory.length) {
                                  // Mocking "OCT 12" style date
                                  final parts = filteredHistory[index].dateLabel
                                      .split(' ');
                                  final label = parts.length >= 2
                                      ? '${parts[0].toUpperCase()} ${parts[1]}'
                                      : 'TODAY';

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: Text(
                                      index == filteredHistory.length - 1
                                          ? 'TODAY'
                                          : label,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white54,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                              interval: 1,
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: filteredHistory.asMap().entries.map((e) {
                              return FlSpot(
                                e.key.toDouble(),
                                e.value.profitLoss,
                              );
                            }).toList(),
                            isCurved: false, // Design shows strict jagged lines
                            color: const Color(0xFF10B981), // Neon Green
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              checkToShowDot: (spot, barData) =>
                                  spot.x == filteredHistory.length - 1,
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                    radius: 4,
                                    color: const Color(0xFF10B981),
                                    strokeWidth: 2,
                                    strokeColor: const Color(0xFF1C1C23),
                                  ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF10B981).withOpacity(0.3),
                                  const Color(0xFF10B981).withOpacity(0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. Personal Records & Stats (2x2 Grid)
            Row(
              children: [
                Expanded(
                  child: _buildGridStatCard(
                    'TOTAL GAMES',
                    '${_stats!.totalGames}',
                    Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGridStatCard(
                    'WINNING %',
                    '$winPercentage%',
                    Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildGridStatCard(
                    'BIGGEST WIN',
                    '+₹${_stats!.biggestWin.toStringAsFixed(0)}',
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGridStatCard(
                    'BIGGEST LOSS',
                    _stats!.biggestLoss < 0
                        ? '-₹${_stats!.biggestLoss.abs().toStringAsFixed(0)}'
                        : '₹0',
                    const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'WINNING STREAKS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white54,
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildStreakCard(
              'Current streak',
              _formatStreakText(_stats!.currentStreak),
              Icons.local_fire_department,
              const Color(0xFFEA580C),
              '🔥',
            ),
            const SizedBox(height: 16),
            _buildStreakCard(
              'Best winning streak',
              '${_stats!.bestWinStreak} wins',
              Icons.emoji_events,
              const Color(0xFFCA8A04),
              '🏆',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF1C1C23),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildGridStatCard(String title, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C23),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(
    String title,
    String value,
    IconData icon,
    Color iconBgColor,
    String trailingEmoji,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C23),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconBgColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Colors.white54),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Text(trailingEmoji, style: const TextStyle(fontSize: 24)),
        ],
      ),
    );
  }

  String _formatStreakText(int streak) {
    if (streak > 0) return '$streak wins';
    if (streak < 0) return '${streak.abs()} losses';
    return '0 wins';
  }
}
