import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const WordChallengeSoloApp());
}

class WordChallengeSoloApp extends StatelessWidget {
  const WordChallengeSoloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Challenge Solo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
