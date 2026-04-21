import 'package:flutter/material.dart';
import 'shimmer_widget.dart';

class GameScreenSkeleton extends StatelessWidget {
  const GameScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return ShimmerWrap(
      SingleChildScrollView(
        padding: EdgeInsets.all(width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // One list tile
            Row(
              children: [
                ShimmerBox(
                  height: 50,
                  width: 50,
                  radius: 25,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLine(
                      height: 16,
                      width: width * 0.5,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    ShimmerLine(
                      height: 12,
                      width: width * 0.3,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // One card
            Container(
              height: width * 0.5,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: EdgeInsets.all(width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLine(
                    height: 20,
                    width: width * 0.6,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  ShimmerLine(
                    height: 14,
                    width: width * 0.8,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  ShimmerLine(
                    height: 14,
                    width: width * 0.7,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100), // Space for button

            // Bottom Button
            ShimmerBox(
              height: 56,
              width: double.infinity,
              radius: 28,
              color: Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}
