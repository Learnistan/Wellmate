import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

class CurvedNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CurvedNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      index: currentIndex,
      height: 60,
      backgroundColor: Colors.transparent,
      color: Colors.blue,
      animationDuration: const Duration(milliseconds: 300),
      items: const [
        Icon(Icons.home),
        Icon(Icons.sports_esports),
        Icon(Icons.fitness_center),
        Icon(Icons.book),
        Icon(Icons.person),
      ],
      onTap: onTap,
    );
  }
}