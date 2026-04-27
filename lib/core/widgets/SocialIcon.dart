import 'package:flutter/material.dart';

class SocialIcon extends StatelessWidget {
  final String path;
  final double size;
  final double containerWidth;
  final double containerHeight;

  const SocialIcon({
    super.key,
    required this.path,
    this.size = 30,
    this.containerWidth = 50,
    this.containerHeight = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
    );
  }
}