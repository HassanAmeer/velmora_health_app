import 'package:flutter/material.dart';
import 'package:velmora/constants/app_colors.dart';

/// Branded circular loader widget
class AppCircularLoader extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const AppCircularLoader({
    super.key,
    this.size = 32,
    this.strokeWidth = 3,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.brandPurple,
        ),
      ),
    );
  }
}

/// Generic fallback skeleton (3 cards)
class AppPageSkeleton extends StatelessWidget {
  const AppPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _line(22, 0.5),
        const SizedBox(height: 20),
        _rowCard(),
        const SizedBox(height: 14),
        _rowCard(),
        const SizedBox(height: 14),
        _rowCard(),
        const SizedBox(height: 14),
        _rowCard(),
      ],
    );
  }

  Widget _rowCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(14, 0.6),
              const SizedBox(height: 8),
              _line(12, 0.9),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _line(double height, double widthFactor) => FractionallySizedBox(
    widthFactor: widthFactor,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
