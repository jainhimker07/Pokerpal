import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/progress_service.dart';
import '../services/performance_service.dart';
import '../models/game_model.dart';
import '../utils/formatter.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final _progressService = ProgressService();
  final _performanceService = PerformanceService();
  
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

    final allGames = await _progressService.loadGames();
    final stats = _performanceService.getStats(allGames, user.uid, userEmail: user.email);
    
    // Apply dummy filtering logic here if needed, 
    // but typically we filter the history points for the graph 
    // while keeping "Overall P/L" and "Records" based on ALL time or filtered time?
    // Requirement: "Overall Profit / Loss ... First thing visible" -> Usually implies All Time.
    // Requirement: "Filter Control ... Filter options: Last 5 games (default)..."
    // Requirement item 3: "Time Series Graph... Default view shows last 5 games"
    
    // Interpretation: 
    // Header P/L: All Time (User says "Overall profit/loss... cumulative... across all games")
    // Graph: Filtered (User says "Filter Control... Place this below overall profit/loss and above graph")
    
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
      return history.length > 10 ? history.sublist(history.length - 10) : history;
    } else if (_filter == 'Last 30 Days') {
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      return history.where((p) => p.date.isAfter(cutoff)).toList();
    }
    
    return history;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stats == null || _stats!.totalGames == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No games played yet.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadStats,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final isProfit = _stats!.totalProfitLoss >= 0;
    final color = isProfit ? Colors.green : Colors.red;
    final filteredHistory = _getFilteredHistory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Overall Profit / Loss
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      isProfit ? '+${Formatter.currency(_stats!.totalProfitLoss)}' : Formatter.currency(_stats!.totalProfitLoss),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isProfit ? 'Overall Profit' : 'Overall Loss',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isProfit ? "You're up overall! 🚀" : "You're down overall 📉",
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 2. Filter Control
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('Last 5'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Last 10'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Last 30 Days'),
                  const SizedBox(width: 8),
                  _buildFilterChip('All Time'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 3. Time Series Graph
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < filteredHistory.length) {
                             // Show every other label if dense
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                filteredHistory[index].dateLabel.split(' ')[0], // Just Month? Or Day? User said "Session Date"
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        interval: 1,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false), // Hide Y axis for clean look
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
                         return FlSpot(e.key.toDouble(), e.value.profitLoss);
                      }).toList(),
                      isCurved: true,
                      color: Colors.deepPurple,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.deepPurple.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 4. Personal Records & Stats
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Personal Records',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Best Win', 
                    '+${Formatter.currency(_stats!.biggestWin)}',
                    Colors.green,
                    Icons.emoji_events,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Biggest Loss', 
                    Formatter.currency(_stats!.biggestLoss), // It's negative
                    Colors.red,
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Current Streak', 
                    _formatStreak(_stats!.currentStreak),
                    _stats!.currentStreak >= 0 ? Colors.green : Colors.red,
                    Icons.timeline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Best Win Streak', 
                    '${_stats!.bestWinStreak} Wins',
                    Colors.orange,
                    Icons.local_fire_department,
                  ),
                ),
              ],
            ),
            
             const SizedBox(height: 16),
             
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: Colors.grey.shade200),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceAround,
                 children: [
                   _buildMiniStat('Games', '${_stats!.totalGames}'),
                   _buildMiniStat('Wins', '${_stats!.wins}', color: Colors.green),
                   _buildMiniStat('Losses', '${_stats!.losses}', color: Colors.red),
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filter = label);
      },
      selectedColor: Colors.deepPurple,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMiniStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  String _formatStreak(int streak) {
    if (streak > 0) return '$streak Wins 🔥';
    if (streak < 0) return '${streak.abs()} Losses ❄️';
    return 'Even';
  }
}
