import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';

/// A wrapper that applies a safe shimmer effect to its child,
/// replacing the old crash-prone Positioned.fill Stack approach.
class ShimmerWrap extends StatelessWidget {
  final Widget child;
  const ShimmerWrap(this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    return child
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1200.ms,
          color: AppColors.brandPurple.withValues(alpha: 0.2),
        );
  }
}

class ShimmerBox extends StatelessWidget {
  final double height;
  final double width;
  final double radius;
  final Color? color;

  const ShimmerBox({
    super.key,
    required this.height,
    required this.width,
    this.radius = 8.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color ?? Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class ShimmerLine extends StatelessWidget {
  final double height;
  final double width;
  final Color? color;

  const ShimmerLine({
    super.key,
    required this.height,
    required this.width,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.grey.shade300,
        borderRadius: BorderRadius.circular(height * 0.5),
      ),
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  final double radius;
  final Color? color;

  const ShimmerCircle({super.key, required this.radius, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: radius * 2,
      width: radius * 2,
      decoration: BoxDecoration(
        color: color ?? Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }
}

class ShimmerListTile extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerListTile({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ShimmerCircle(radius: height * 0.25),
        SizedBox(width: width * 0.04),
        SizedBox(
          width: width * 0.55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShimmerLine(height: height * 0.02, width: width * 0.5),
              SizedBox(height: height * 0.01),
              ShimmerLine(height: height * 0.015, width: width * 0.8),
            ],
          ),
        ),
      ],
    );
  }
}

class ShimmerGridBox extends StatelessWidget {
  final double size;
  final double radius;

  const ShimmerGridBox({super.key, required this.size, this.radius = 16.0});

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(height: size, width: size, radius: radius);
  }
}
