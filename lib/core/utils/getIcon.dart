import 'package:flutter/material.dart';

IconData getIcon(String key) {
  switch (key) {
    case 'air':
      return Icons.air;
    case 'walk':
      return Icons.directions_walk;
    case 'water':
      return Icons.water_drop_outlined;
    case 'check':
      return Icons.check_box_outlined;
    case 'body':
      return Icons.man;
    case 'psychology':
      return Icons.psychology_alt_outlined;
    case 'bubbles':
      return Icons.bubble_chart_outlined;
    case 'mood':
      return Icons.mood;
    case 'sun':
      return Icons.sunny;
    case 'moon':
      return Icons.nightlight;
    default:
      return Icons.circle;
  }
}