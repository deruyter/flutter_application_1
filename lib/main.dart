import 'package:flutter/material.dart';
import 'src/pages/home_page.dart';

void main() {
  runApp(const TennisStatsApp());
}

class TennisStatsApp extends StatelessWidget {
  const TennisStatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tennis Stats',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
