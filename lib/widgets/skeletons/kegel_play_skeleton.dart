import 'package:flutter/material.dart';
import 'shimmer_widget.dart';

import '../../../constants/app_colors.dart';

class KegelPlaySkeleton extends StatelessWidget {
  const KegelPlaySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;

    return ShimmerWrap(
      Column(
        children: [
          // Header
          Container(
            height: height * 0.15,
            color: AppColors.brandPurple,
            padding: EdgeInsets.fromLTRB(
              width * 0.067,
              height * 0.06,
              width * 0.067,
              0,
            ),
            child: Row(
              children: [
                ShimmerBox(
                  height: height * 0.03,
                  width: height * 0.03,
                  radius: width * 0.067,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                SizedBox(width: width * 0.033),
                ShimmerLine(
                  height: height * 0.025,
                  width: width * 0.4,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          // Content
          SizedBox(
            height: height * 0.65,
            child: ListView(
              padding: EdgeInsets.all(width * 0.067),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Progress bar
                ShimmerLine(
                  height: height * 0.0125,
                  width: width,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: height * 0.03),
                // Timer circle
                Center(
                  child: ShimmerBox(
                    height: height * 0.275,
                    width: height * 0.275,
                    radius: width * 0.61,
                    color: Colors.grey.shade300,
                  ),
                ),
                SizedBox(height: height * 0.05),
                // Phase text
                Center(
                  child: ShimmerLine(
                    height: height * 0.03,
                    width: width * 0.45,
                    color: Colors.grey.shade300,
                  ),
                ),
                SizedBox(height: height * 0.03),
                // Cycle dots
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: width * 0.017,
                  children: List.generate(
                    10,
                    (index) => ShimmerBox(
                      height: height * 0.015,
                      width: height * 0.015,
                      radius: width * 0.017,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),
                SizedBox(height: height * 0.05),
                // Play button
                Center(
                  child: ShimmerBox(
                    height: height * 0.07,
                    width: height * 0.07,
                    radius: width * 0.4,
                    color: Colors.grey.shade300,
                  ),
                ),
                SizedBox(height: height * 0.05),
                // Overall progress
                ShimmerLine(
                  height: height * 0.02,
                  width: width * 0.5,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: height * 0.015),
                Container(
                  height: height * 0.01,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(height * 0.005),
                  ),
                ),
                SizedBox(height: height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerLine(
                      height: height * 0.016,
                      width: width * 0.25,
                      color: Colors.grey.shade300,
                    ),
                    ShimmerLine(
                      height: height * 0.016,
                      width: width * 0.15,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
