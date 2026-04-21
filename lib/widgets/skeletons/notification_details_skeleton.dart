import 'package:flutter/material.dart';
import 'shimmer_widget.dart';

import '../../../constants/app_colors.dart';

class NotificationDetailsSkeleton extends StatelessWidget {
  const NotificationDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;

    return ShimmerWrap(
      Column(
        children: [
          // Small header
          Container(
            height: height * 0.12,
            color: AppColors.brandPurple,
            padding: EdgeInsets.fromLTRB(
              width * 0.067,
              height * 0.05,
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
                  width: width * 0.5,
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
                // Detail card
                Container(
                  padding: EdgeInsets.all(width * 0.056),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(width * 0.056),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon and title
                      Row(
                        children: [
                          ShimmerBox(
                            height: height * 0.06,
                            width: height * 0.06,
                            radius: width * 0.133,
                            color: Colors.grey.shade300,
                          ),
                          SizedBox(width: width * 0.044),
                          SizedBox(
                            width: width * 0.5,
                            child: ShimmerLine(
                              height: height * 0.025,
                              width: width * 0.6,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: height * 0.024),
                      // Divider
                      Container(height: 1, color: Colors.grey.shade200),
                      SizedBox(height: height * 0.024),
                      // Body content
                      ShimmerLine(
                        height: height * 0.0175,
                        width: width,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(height: height * 0.015),
                      ShimmerLine(
                        height: height * 0.0175,
                        width: width * 0.95,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(height: height * 0.015),
                      ShimmerLine(
                        height: height * 0.0175,
                        width: width * 0.85,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(height: height * 0.015),
                      ShimmerLine(
                        height: height * 0.0175,
                        width: width * 0.9,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(height: height * 0.015),
                      ShimmerLine(
                        height: height * 0.0175,
                        width: width * 0.7,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(height: height * 0.03),
                      // Timestamp
                      ShimmerLine(
                        height: height * 0.014,
                        width: width * 0.3,
                        color: Colors.grey.shade300,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
