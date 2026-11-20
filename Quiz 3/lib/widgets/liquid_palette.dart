import 'package:flutter/material.dart';

/// The liquid colours, in the order levels use them.
class LiquidPalette {
  static const colors = <Color>[
    Color(0xFFE53935), // red
    Color(0xFF1E88E5), // blue
    Color(0xFF43A047), // green
    Color(0xFFFDD835), // yellow
    Color(0xFF8E24AA), // purple
    Color(0xFFFB8C00), // orange
    Color(0xFFEC407A), // pink
    Color(0xFF00ACC1), // cyan
    Color(0xFF6D4C41), // brown
    Color(0xFF9CCC65), // lime
    Color(0xFF5C6BC0), // indigo
    Color(0xFFFF7043), // deep orange
  ];

  static Color of(int index) => colors[index % colors.length];

  /// A slightly lighter tint used for the highlight band inside each layer.
  static Color highlightOf(int index) =>
      Color.lerp(of(index), Colors.white, 0.28)!;

  /// A darker tone used at the bottom edge of a layer so the liquid reads as
  /// having depth rather than being flat.
  static Color shadowOf(int index) =>
      Color.lerp(of(index), Colors.black, 0.25)!;
}
