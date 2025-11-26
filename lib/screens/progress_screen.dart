import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game_model.dart';
import '../services/progress_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _progressService = ProgressService();
  bool _loading = true;
  List<GameModel> _history = [];
  Map<String, _PlayerProgress> _progress = {};
  String? _selectedPlayer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final games = await _progressService.loadGames();
    final progress = _buildProgress(games);
    setState(() {
      _history = games;
      _progress = progress;
      _selectedPlayer = progress.keys.isNotEmpty ? progress.keys.first : null;
      _loading = false;
    });
  }

  Map<String, _PlayerProgress> _buildProgress(List<GameModel> games) {
    final Map<String, _PlayerProgressBuilder> builders = {};

    for (final game in games) {
      for (final result in game.results) {
        final builder = builders.putIfAbsent(
          result.name,
          () => _PlayerProgressBuilder(name: result.name),
        );
        builder.gamesPlayed++;
        builder.totalProfit += result.netProfit;
        if (result.netProfit > 0) builder.wins++;
        if (result.netProfit < 0) builder.losses++;
        builder.trendPoints.add(
          _TrendPoint(date: game.createdAt, profit: result.netProfit),
        );

        for (final opponent in game.results.where(
          (p) => p.name != result.name,
        )) {
          builder.versus[opponent.name] =
              (builder.versus[opponent.name] ?? 0) + result.netProfit;
        }
      }
    }

    return builders.map((key, value) => MapEntry(key, value.build()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected =
        _selectedPlayer != null ? _progress[_selectedPlayer] : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _load,
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                ? ListView(
                  children: const [
                    SizedBox(height: 140),
                    Icon(Icons.insights_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Finish a game to start tracking progress.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                )
                : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Player Overview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._progress.values.map(
                      (p) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary
                                .withOpacity(0.15),
                            child: const Icon(Icons.person),
                          ),
                          title: Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${p.gamesPlayed} games • ${p.wins}W-${p.losses}L\nAvg: ₹${p.averageProfit.toStringAsFixed(0)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                (p.totalProfit >= 0 ? '+₹' : '₹') +
                                    p.totalProfit.abs().toStringAsFixed(0),
                                style: TextStyle(
                                  color:
                                      p.totalProfit >= 0
                                          ? Colors.green
                                          : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Total P/L',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() => _selectedPlayer = p.name);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (selected != null) ...[
                      Row(
                        children: [
                          Text(
                            'Deep Dive',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          DropdownButton<String>(
                            value: selected.name,
                            items:
                                _progress.keys
                                    .map(
                                      (name) => DropdownMenuItem(
                                        value: name,
                                        child: Text(name),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedPlayer = value);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _PlayerHeadline(selected: selected),
                      const SizedBox(height: 16),
                      ProfitChart(points: selected.cumulativeProfit),
                      const SizedBox(height: 16),
                      _OpponentBreakdown(opponents: selected.versus),
                    ],
                  ],
                ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Progress',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
      ),
    );
  }
}

class _PlayerHeadline extends StatelessWidget {
  final _PlayerProgress selected;

  const _PlayerHeadline({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.15),
              child: const Icon(Icons.person, size: 28),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${selected.gamesPlayed} games • ${selected.wins}W-${selected.losses}L',
                ),
                Text(
                  'Total: ${(selected.totalProfit >= 0 ? '+₹' : '₹')}${selected.totalProfit.abs().toStringAsFixed(0)}',
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    selected.totalProfit >= 0
                        ? Colors.green.withOpacity(0.12)
                        : Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    'Win %',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    selected.winRate.toStringAsFixed(0) + '%',
                    style: TextStyle(
                      color:
                          selected.totalProfit >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfitChart extends StatelessWidget {
  final List<double> points;

  const ProfitChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profit Trend',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: CustomPaint(
              painter: _ProfitPainter(
                points: points,
                color: theme.colorScheme.primary,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            points.isEmpty
                ? 'No games yet'
                : 'Latest: ₹${points.last.toStringAsFixed(0)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _OpponentBreakdown extends StatelessWidget {
  final Map<String, double> opponents;

  const _OpponentBreakdown({required this.opponents});

  @override
  Widget build(BuildContext context) {
    if (opponents.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries =
        opponents.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final winners = entries.where((e) => e.value > 0).take(3).toList();
    final nemeses = entries.where((e) => e.value < 0).take(3).toList();

    Widget buildChip(String name, double amount, Color color) {
      return Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${amount >= 0 ? '+' : '-'}₹${amount.abs().toStringAsFixed(0)} vs $name',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Who you beat',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (winners.isEmpty)
              const Text(
                'No winning edge yet.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Wrap(
                children:
                    winners
                        .map((e) => buildChip(e.key, e.value, Colors.green))
                        .toList(),
              ),
            const SizedBox(height: 14),
            const Text(
              'Who troubles you',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (nemeses.isEmpty)
              const Text(
                'No nemesis so far.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Wrap(
                children:
                    nemeses
                        .map((e) => buildChip(e.key, e.value, Colors.red))
                        .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfitPainter extends CustomPainter {
  final List<double> points;
  final Color color;

  _ProfitPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final minY = points.reduce(min);
    final maxY = points.reduce(max);
    final range = (maxY - minY).abs() < 1 ? 1.0 : maxY - minY;

    final stepX =
        points.length == 1 ? size.width : size.width / (points.length - 1);
    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normalized = (points[i] - minY) / range;
      final y = size.height - (normalized * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paintLine =
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

    final gradient =
        Paint()
          ..shader = LinearGradient(
            colors: [color.withOpacity(0.25), color.withOpacity(0.02)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill;

    final fillPath =
        Path.from(path)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

    canvas.drawPath(fillPath, gradient);
    canvas.drawPath(path, paintLine);

    final pointPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normalized = (points[i] - minY) / range;
      final y = size.height - (normalized * size.height);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }

    // Draw zero line if it lies within the chart range.
    if (minY < 0 && maxY > 0) {
      final zeroY = size.height - ((0 - minY) / range) * size.height;
      final zeroPaint =
          Paint()
            ..color = Colors.grey.withOpacity(0.4)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProfitPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

class _PlayerProgressBuilder {
  final String name;
  int gamesPlayed = 0;
  double totalProfit = 0;
  int wins = 0;
  int losses = 0;
  final List<_TrendPoint> trendPoints = [];
  final Map<String, double> versus = {};

  _PlayerProgressBuilder({required this.name});

  _PlayerProgress build() {
    trendPoints.sort((a, b) => a.date.compareTo(b.date));
    final cumulative = <double>[];
    double running = 0;
    for (final point in trendPoints) {
      running += point.profit;
      cumulative.add(running);
    }

    return _PlayerProgress(
      name: name,
      gamesPlayed: gamesPlayed,
      totalProfit: totalProfit,
      wins: wins,
      losses: losses,
      cumulativeProfit: cumulative,
      versus: versus,
    );
  }
}

class _PlayerProgress {
  final String name;
  final int gamesPlayed;
  final double totalProfit;
  final int wins;
  final int losses;
  final List<double> cumulativeProfit;
  final Map<String, double> versus;

  _PlayerProgress({
    required this.name,
    required this.gamesPlayed,
    required this.totalProfit,
    required this.wins,
    required this.losses,
    required this.cumulativeProfit,
    required this.versus,
  });

  double get averageProfit => gamesPlayed == 0 ? 0 : totalProfit / gamesPlayed;

  double get winRate {
    if (gamesPlayed == 0) return 0;
    return (wins / gamesPlayed) * 100;
  }
}

class _TrendPoint {
  final DateTime date;
  final double profit;

  _TrendPoint({required this.date, required this.profit});
}
