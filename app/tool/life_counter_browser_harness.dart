import 'package:flutter/material.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

/// Serves the production Life Counter surface without authentication so mouse,
/// touch and keyboard behavior can be inspected in a real browser build.
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LotusLifeCounterScreen(),
    ),
  );
}
