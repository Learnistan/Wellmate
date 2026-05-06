import 'package:flutter/material.dart';

IconData getIcon(String key) {
  switch (key) {
    case 'air':
      return Icons.air;
    case 'walk':
      return Icons.directions_walk;
    case 'water':
      return Icons.water_drop_outlined;
    case 'fire':
      return Icons.local_fire_department;
    case 'man':
      return Icons.man;
    default:
      return Icons.circle;
  }
}