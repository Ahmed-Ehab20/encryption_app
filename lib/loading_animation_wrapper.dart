import 'package:flutter/material.dart';
import 'loading_animation.dart';

/// This is a wrapper around the LoadingAnimation widget
/// Use this instead of directly using LoadingAnimation in the main.dart file
/// to avoid any potential issues with duplicate dispose methods
class LoadingAnimationWrapper extends StatelessWidget {
  final double size;
  final Color color;

  const LoadingAnimationWrapper({
    Key? key,
    this.size = 60.0,
    this.color = const Color(0xFF6B4EFF),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LoadingAnimation(
      size: size,
      color: color,
    );
  }
}
