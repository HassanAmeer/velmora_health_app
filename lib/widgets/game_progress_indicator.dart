import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:velmora/utils/responsive_sizer.dart';

/// Games that should show the **circle** question counter.
const Set<String> _circleGames = {
  'truth_or_truth',
  'relationship_quiz',
  'love_language_quiz',
};

/// A unified progress indicator for game screens.
///
/// Pass [gameId] to automatically pick the right style:
///   - Games in [_circleGames] → animated circular arc with question number.
///   - All other games → pill-shaped progress bar.
class GameProgressIndicator extends StatelessWidget {
  const GameProgressIndicator({
    super.key,
    required this.gameId,
    required this.current,
    required this.total,
    required this.color,
    this.label,
    this.trailingWidget,
  });

  /// The game identifier (e.g. `'truth_or_truth'`).
  final String gameId;

  /// Current question / step (1-based).
  final int current;

  /// Total questions / steps.
  final int total;

  /// Theme colour for the indicator.
  final Color color;

  /// Optional label shown to the left of the indicator (e.g. "Question 3 of 10").
  final String? label;

  /// Optional widget shown on the right side (e.g. player scores).
  final Widget? trailingWidget;

  bool get _useCircle => _circleGames.contains(gameId);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      color: Colors.white,
      child: Row(
        children: [
          // Left: label or circle (circle games put label inside the circle)
          if (_useCircle) ...[
            _CircleCounter(current: current, total: total, color: color),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null)
                    Text(
                      label!,
                      style: TextStyle(
                        fontSize: 13.fSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2933),
                      ),
                    ),
                  if (trailingWidget != null) ...[
                    SizedBox(height: 4.h),
                    trailingWidget!,
                  ],
                ],
              ),
            ),
          ] else ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (label != null)
                        Text(
                          label!,
                          style: TextStyle(
                            fontSize: 13.fSize,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      if (trailingWidget != null) trailingWidget!,
                    ],
                  ),
                  SizedBox(height: 8.h),
                  _PillProgressBar(value: current / total, color: color),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Circle counter  (used for quiz-style games)
// ─────────────────────────────────────────────
class _CircleCounter extends StatelessWidget {
  const _CircleCounter({
    required this.current,
    required this.total,
    required this.color,
  });

  final int current;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;
    final size = 52.adaptSize;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArcPainter(
          progress: progress,
          color: color,
          trackColor: color.withOpacity(0.15),
          strokeWidth: 4.0,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$current',
                style: TextStyle(
                  fontSize: 16.fSize,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1,
                ),
              ),
              Container(
                width: 14.w,
                height: 1,
                color: color.withOpacity(0.4),
                margin: EdgeInsets.symmetric(vertical: 1.h),
              ),
              Text(
                '$total',
                style: TextStyle(
                  fontSize: 10.fSize,
                  color: Colors.grey.shade500,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Track (full circle)
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, trackPaint);
    // Progress arc
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────
// Pill progress bar  (used for card-style games)
// ─────────────────────────────────────────────
class _PillProgressBar extends StatelessWidget {
  const _PillProgressBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 8.h,
        backgroundColor: color.withOpacity(0.15),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
