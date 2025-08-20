import 'package:flutter/material.dart';
import 'puzzle_page.dart';

void main() => runApp(const SlidePuzzleApp());

class SlidePuzzleApp extends StatelessWidget {
  const SlidePuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced Slide Puzzle',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      home: const PuzzlePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
