import 'package:flutter/material.dart';
import 'shimmer_widget.dart';

import '../../../constants/app_colors.dart';

class SubscriptionScreenSkeleton extends StatelessWidget {
  const SubscriptionScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;

    return ShimmerWrap(
      ListView(
        padding: EdgeInsets.all(width * 0.067),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          SizedBox(height: height * 0.025),

          SizedBox(height: height * 0.03),
          // Premium icon
          Center(
            child: ShimmerBox(
              height: height * 0.095,
              width: height * 0.095,
              radius: width * 0.211,
              color: Colors.grey.shade300,
            ),
          ),
          SizedBox(height: height * 0.025),
          // Title
          Center(
            child: ShimmerLine(
              height: height * 0.035,
              width: width * 0.5,
              color: Colors.grey.shade300,
            ),
          ),
          SizedBox(height: height * 0.0125),
          // Subtitle
          Center(
            child: ShimmerLine(
              height: height * 0.0175,
              width: width * 0.4,
              color: Colors.grey.shade300,
            ),
          ),
          SizedBox(height: height * 0.05),
          // Plan cards
          _planCard(width, height, true),
          SizedBox(height: height * 0.02),
          _planCard(width, height, false),
          SizedBox(height: height * 0.02),
          _planCard(width, height, false),
          SizedBox(height: height * 0.04),
          // Pay button
          ShimmerBox(
            height: height * 0.0625,
            width: height * 0.0625,
            radius: width,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: height * 0.03),
          // Footer icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShimmerBox(
                height: height * 0.03,
                width: height * 0.03,
                radius: width * 0.067,
                color: Colors.grey.shade300,
              ),
              SizedBox(width: width * 0.022),
              ShimmerLine(
                height: height * 0.015,
                width: width * 0.2,
                color: Colors.grey.shade300,
              ),
              SizedBox(width: width * 0.056),
              ShimmerBox(
                height: height * 0.03,
                width: height * 0.03,
                radius: width * 0.067,
                color: Colors.grey.shade300,
              ),
              SizedBox(width: width * 0.022),
              ShimmerLine(
                height: height * 0.015,
                width: width * 0.2,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _planCard(double width, double height, bool isPopular) {
    return Container(
      padding: EdgeInsets.all(width * 0.044),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.044),
        border: Border.all(
          color: isPopular ? AppColors.brandPurple : Colors.grey.shade200,
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          ShimmerBox(
            height: height * 0.055,
            width: height * 0.055,
            radius: width * 0.122,
            color: Colors.grey.shade300,
          ),
          SizedBox(width: width * 0.044),
          SizedBox(
            width: width * 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLine(
                  height: height * 0.02,
                  width: width * 0.35,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: height * 0.008),
                ShimmerLine(
                  height: height * 0.015,
                  width: width * 0.5,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
