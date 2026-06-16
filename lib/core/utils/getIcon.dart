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
    default:
      return Icons.circle;
  }
}