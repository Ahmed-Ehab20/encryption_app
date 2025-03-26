import 'package:flutter/material.dart';
import 'dart:math' show pi, cos, sin;

class LoadingAnimation extends StatefulWidget {
  final double size;
  final Color color;

  const LoadingAnimation({
    Key? key,
    this.size = 40.0,
    this.color = const Color(0xFF6B4EFF),
  }) : super(key: key);

  @override
  _LoadingAnimationState createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _radiusAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _radiusAnimation = Tween<double>(
      begin: widget.size * 0.2,
      end: widget.size * 0.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _CirclePainter(
              rotation: _rotationAnimation.value,
              radius: _radiusAnimation.value,
              color: widget.color,
              dotCount: 8,
            ),
          ),
        );
      },
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double rotation;
  final double radius;
  final Color color;
  final int dotCount;

  _CirclePainter({
    required this.rotation,
    required this.radius,
    required this.color,
    this.dotCount = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final circleRadius = size.width / 2 - radius;

    for (int i = 0; i < dotCount; i++) {
      final angle = rotation + (2 * pi * i / dotCount);
      final offset = Offset(
        center.dx + cos(angle) * circleRadius,
        center.dy + sin(angle) * circleRadius,
      );

      final opacity = 0.3 + (0.7 * i / dotCount);
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_CirclePainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.radius != radius ||
        oldDelegate.color != color;
  }
}
