import '../models/game_model.dart';
import 'package:intl/intl.dart';

class PlayerStats {
  final double totalProfitLoss;
  final List<GameHistoryPoint> gameHistory; // For the graph
  final int currentStreak; // Positive for win streak, negative for loss streak
  final int bestWinStreak;
  final double biggestWin;
  final double biggestLoss; // Stored as negative number
  final int totalGames;
  final int wins;
  final int losses;

  PlayerStats({
    required this.totalProfitLoss,
    required this.gameHistory,
    required this.currentStreak,
    required this.bestWinStreak,
    required this.biggestWin,
    required this.biggestLoss,
    required this.totalGames,
    required this.wins,
    required this.losses,
  });

  bool get isUpOverall => totalProfitLoss >= 0;
}

class GameHistoryPoint {
  final DateTime date;
  final double profitLoss;
  final String dateLabel;

  GameHistoryPoint(this.date, this.profitLoss)
      : dateLabel = DateFormat('MMM d').format(date);
}

class PerformanceService {
  /// Calculates stats for a specific user ID.
  /// If [userId] is null, returns empty stats.
  PlayerStats getStats(List<GameModel> allGames, String? userId, {String? userEmail}) {
    if (userId == null && userEmail == null) {
      return _emptyStats();
    }

    // 1. Filter games where this player participated
    final userGames = allGames.where((game) {
      return game.results.any((player) => 
        (player.userId == userId) || 
        (userEmail != null && player.email == userEmail)
      );
    }).toList();

    // Sort by date ascending (oldest first) for correct graph/streak calculation
    userGames.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (userGames.isEmpty) {
      return _emptyStats();
    }

    double totalPL = 0;
    List<GameHistoryPoint> history = [];
    int currentStreak = 0;
    int bestWinStreak = 0;
    double biggestWin = 0;
    double biggestLoss = 0;
    int wins = 0;
    int losses = 0;

    for (final game in userGames) {
      // Find player's result in this game
      final result = game.results.firstWhere((p) => 
        p.userId == userId || (userEmail != null && p.email == userEmail)
      );

      final pl = result.netProfit;
      
      // Update Totals
      totalPL += pl;
      history.add(GameHistoryPoint(game.createdAt, pl));

      // Update Counts & Extremes
      if (pl > 0) {
        wins++;
        if (pl > biggestWin) biggestWin = pl;
        
        // Streak Logic
        if (currentStreak >= 0) {
          currentStreak++;
        } else {
          currentStreak = 1; // Reset to 1st win
        }
      } else if (pl < 0) {
        losses++;
        if (pl < biggestLoss) biggestLoss = pl; // biggestLoss is negative, so finding min

        // Streak Logic
        if (currentStreak <= 0) {
          currentStreak--; 
        } else {
          currentStreak = -1; // Reset to 1st loss
        }
      } else {
        // Break even resets streak? Or ignores? 
        // Let's reset for simplicity or treat as neutral. 
        // Implementation choice: Reset streak on perceived "draw"? 
        // Usually poker has small wins/losses, exact 0 is rare unless explicitly entered.
        // Let's keep streak if 0, or maybe reset. Resetting is safer.
        currentStreak = 0;
      }

      if (currentStreak > bestWinStreak) {
        bestWinStreak = currentStreak;
      }
    }

    return PlayerStats(
      totalProfitLoss: totalPL,
      gameHistory: history,
      currentStreak: currentStreak,
      bestWinStreak: bestWinStreak,
      biggestWin: biggestWin,
      biggestLoss: biggestLoss,
      totalGames: userGames.length,
      wins: wins,
      losses: losses,
    );
  }

  PlayerStats _emptyStats() {
    return PlayerStats(
      totalProfitLoss: 0,
      gameHistory: [],
      currentStreak: 0,
      bestWinStreak: 0,
      biggestWin: 0,
      biggestLoss: 0,
      totalGames: 0,
      wins: 0,
      losses: 0,
    );
  }
}
