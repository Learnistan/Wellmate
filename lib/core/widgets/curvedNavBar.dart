import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wellmate/core/theme/colors.dart';

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
    final List<Map<String, String>> navItems = [
      {
        'active': 'assets/icons/ic_home_active.svg',
        'inactive': 'assets/icons/ic_home_inactive.svg',
      },
      {
        'active': 'assets/icons/ic_games_active.svg',
        'inactive': 'assets/icons/ic_games_inactive.svg',
      },
      {
        'active': 'assets/icons/ic_dailyActivities_active.svg',
        'inactive': 'assets/icons/ic_dailyActivities_inactive.svg',
      },
      {
        'active': 'assets/icons/ic_journal_active.svg',
        'inactive': 'assets/icons/ic_journal_inactive.svg',
      },
      {
        'active': 'assets/icons/ic_profile_active.svg',
        'inactive': 'assets/icons/ic_profile_inactive.svg',
      },
    ];

    return CurvedNavigationBar(
      index: currentIndex,
      height: 60,
      backgroundColor: Colors.transparent,
      color: AppColors.primary,
      buttonBackgroundColor: Colors.white,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      items: List.generate(
        navItems.length,
            (index) {
          final bool isSelected = currentIndex == index;

          return SvgPicture.asset(
            isSelected
                ? navItems[index]['active']!
                : navItems[index]['inactive']!,
            width: 24,
            height: 24,
          );
        },
      ),
      onTap: onTap,
    );
  }
}