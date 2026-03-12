import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/result_screen.dart';
import 'screens/settlement_screen.dart';
import 'screens/add_player_screen.dart';
import 'screens/buyin_screen.dart';
import 'screens/player_screen.dart';
import 'screens/login_screen.dart';
import 'screens/progress_screen.dart';
import 'theme/app_theme.dart';

// Import the group feature
import 'screens/groups/group_list_screen.dart';

class PokerPalApp extends StatelessWidget {
  const PokerPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokerPal',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/game': (context) => const GameScreen(),
        '/result': (context) => const ResultScreen(),
        '/settlement': (context) => const SettlementScreen(),
        '/buyins': (context) => const BuyInScreen(),
        '/player': (context) => const PlayerScreen(),
        '/add-player': (context) => const AddPlayerScreen(),
        '/groups': (context) => const GroupListScreen(),
        '/progress': (context) => const ProgressScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if user is logged in
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
