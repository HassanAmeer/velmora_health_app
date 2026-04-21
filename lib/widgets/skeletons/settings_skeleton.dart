import 'package:flutter/material.dart';
import 'shimmer_widget.dart';

import '../../../constants/app_colors.dart';

class SettingsScreenSkeleton extends StatelessWidget {
  const SettingsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;

    return ShimmerWrap(
      Column(
        children: [
          // Purple header
          Container(
            width: double.infinity,
            height: height * 0.225,
            decoration: BoxDecoration(
              color: AppColors.brandPurple,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(width * 0.11),
                bottomRight: Radius.circular(width * 0.11),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              width * 0.067,
              height * 0.1,
              width * 0.067,
              0,
            ),
            child: ShimmerLine(
              height: height * 0.04,
              width: width * 0.4,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          // Settings groups
          SizedBox(
            height: height * 0.65,
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.067,
                vertical: height * 0.019,
              ),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _settingsGroup(width, height, 2),
                SizedBox(height: height * 0.025),
                _settingsGroup(width, height, 3),
                SizedBox(height: height * 0.025),
                _settingsGroup(width, height, 1),
                SizedBox(height: height * 0.025),
                _settingsGroup(width, height, 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsGroup(double width, double height, int itemCount) {
    return Container(
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
        children: List.generate(
          itemCount,
          (index) => _settingsItem(width, height, index == itemCount - 1),
        ),
      ),
    );
  }

  Widget _settingsItem(double width, double height, bool isLast) {
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
            radius: width * 0.033,
            color: Colors.grey.shade300,
          ),
          SizedBox(width: width * 0.044),
          ShimmerLine(
            height: height * 0.02,
            width: width * 0.35,
            color: Colors.grey.shade300,
          ),
          const Spacer(),
          ShimmerBox(
            height: height * 0.03,
            width: height * 0.03,
            radius: width * 0.067,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
