import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/result_screen.dart';
import 'screens/settlement_screen.dart';
import 'screens/add_player_screen.dart';
import 'screens/buyin_screen.dart';
import 'screens/player_screen.dart';


class PokerPalApp extends StatelessWidget {
  const PokerPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokerPal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/game': (context) => const GameScreen(),
        '/result': (context) => const ResultScreen(),
        '/settlement': (context) => const SettlementScreen(),
        '/buyins': (context) => const BuyInScreen(),
        '/player': (context) => const PlayerScreen(),
        '/add-player': (context) => const AddPlayerScreen(),
        // Add other screens like '/game', '/players' here later
      },
    );
  }
}