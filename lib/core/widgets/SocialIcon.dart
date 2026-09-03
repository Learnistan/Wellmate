import 'package:flutter/material.dart';

class SocialIcon extends StatelessWidget {
  final String path;
  final double size;
  final double containerWidth;
  final double containerHeight;
  final VoidCallback? onTap;

  const SocialIcon({
    super.key,
    required this.path,
    this.size = 30,
    this.containerWidth = 50,
    this.containerHeight = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: containerWidth,
        height: containerHeight,
        child: Center(
          child: Image.asset(
            path,
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}