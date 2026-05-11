import 'package:flutter/material.dart';

/// Shared palette: day pill, polyline, and markers use the same color per day index.
class TripDayRouteColors {
  TripDayRouteColors._();

  static const List<Color> accentsLight = [
    Color(0xFF1A2B49),
    Color(0xFFE85D4C),
    Color(0xFF2E8B7E),
    Color(0xFFC45BAA),
    Color(0xFF4A6FA5),
    Color(0xFFD4940C),
  ];

  static const List<Color> accentsDark = [
    Color(0xFF7A9FE8),
    Color(0xFFFF9A8B),
    Color(0xFF5FD4C4),
    Color(0xFFE89FD8),
    Color(0xFF9BB8E8),
    Color(0xFFFFC857),
  ];

  static Color accentFor(BuildContext context, int dayIndexZeroBased) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final list = dark ? accentsDark : accentsLight;
    return list[dayIndexZeroBased % list.length];
  }
}
