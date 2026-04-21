import 'package:flutter/material.dart';
import 'shimmer_widget.dart';

import '../../../constants/app_colors.dart';

class HelpSupportSkeleton extends StatelessWidget {
  const HelpSupportSkeleton({super.key});

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
                // FAQ section
                _sectionCard(width, height, 'FAQ'),
                SizedBox(height: height * 0.024),
                // Resources section
                _sectionCard(width, height, 'Resources'),
                SizedBox(height: height * 0.024),
                // About card
                _aboutCard(width, height),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(double width, double height, String title) {
    return Container(
      padding: EdgeInsets.all(width * 0.044),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.044),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLine(
            height: height * 0.0225,
            width: width * 0.3,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: height * 0.02),
          _helpItem(width, height),
          SizedBox(height: height * 0.015),
          _helpItem(width, height),
          SizedBox(height: height * 0.015),
          _helpItem(width, height),
        ],
      ),
    );
  }

  Widget _helpItem(double width, double height) {
    return Row(
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
                height: height * 0.0175,
                width: width * 0.5,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: height * 0.008),
              ShimmerLine(
                height: height * 0.014,
                width: width * 0.7,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _aboutCard(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.044),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.044),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo placeholder
          ShimmerBox(
            height: height * 0.1,
            width: height * 0.1,
            radius: width * 0.222,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: height * 0.024),
          ShimmerLine(
            height: height * 0.025,
            width: width * 0.5,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: height * 0.015),
          ShimmerLine(
            height: height * 0.0175,
            width: width * 0.7,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: height * 0.015),
          ShimmerLine(
            height: height * 0.0175,
            width: width * 0.6,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
