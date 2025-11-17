import 'package:flutter/material.dart';
import 'ui/create_draw_screen.dart';
// removed unused imports to keep project minimal — main app uses CreateDrawScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tennis Draw Creator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CreateDrawScreen(),
    );
  }
}

// Removed large example App class that referenced missing 'src' utilities.
// The project uses `CreateDrawScreen` as the app's home widget (see `MyApp`).
