import 'package:flutter/material.dart';
import 'shimmer_widget.dart';

import '../../../constants/app_colors.dart';

class PrivacySecuritySkeleton extends StatelessWidget {
  const PrivacySecuritySkeleton({super.key});

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
                  width: width * 0.45,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          // Settings list
          SizedBox(
            height: height * 0.65,
            child: ListView(
              padding: EdgeInsets.all(width * 0.067),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Settings group
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(width * 0.056),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _settingsItem(
                        width,
                        height,
                        Icons.policy_outlined,
                        false,
                      ),
                      _settingsItem(width, height, Icons.lock_outline, false),
                      _settingsItem(width, height, Icons.delete_outline, true),
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

  Widget _settingsItem(
    double width,
    double height,
    IconData icon,
    bool isLast,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.044,
        vertical: height * 0.0225,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Row(
        children: [
          ShimmerBox(
            height: height * 0.055,
            width: height * 0.055,
            radius: width * 0.111,
            color: Colors.grey.shade300,
          ),
          SizedBox(width: width * 0.044),
          ShimmerLine(
            height: height * 0.02,
            width: width * 0.4,
            color: Colors.grey.shade300,
          ),
          const Spacer(),
          ShimmerBox(
            height: height * 0.03,
            width: height * 0.03,
            radius: width * 0.056,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
