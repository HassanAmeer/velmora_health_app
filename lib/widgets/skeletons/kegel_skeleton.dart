import 'package:flutter/material.dart';
import 'shimmer_widget.dart';

import '../../../constants/app_colors.dart';

class KegelScreenSkeleton extends StatelessWidget {
  const KegelScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;

    return ShimmerWrap(
      Column(
        children: [
          // Gradient header
          Container(
            height: height * 0.22,
            width: width,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B5EE2), Color(0xFF9F8BF5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(width * 0.11),
                bottomRight: Radius.circular(width * 0.11),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              width * 0.067,
              height * 0.06,
              width * 0.067,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 30),
                ShimmerLine(
                  height: height * 0.035,
                  width: width * 0.35,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                SizedBox(height: height * 0.015),
                ShimmerLine(
                  height: height * 0.02,
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
              padding: EdgeInsets.all(width * 0.056),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Progress card
                _progressCard(width, height),
                SizedBox(height: height * 0.024),
                // Challenge banner
                _challengeBanner(width, height),
                SizedBox(height: height * 0.024),
                // Routine cards
                _routineCard(width, height),
                SizedBox(height: height * 0.024),
                _routineCard(width, height),
                SizedBox(height: height * 0.024),
                // Info cards
                _infoCard(width, height),
                SizedBox(height: height * 0.024),
                _infoCard(width, height),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressCard(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLine(
                    height: height * 0.0225,
                    width: width * 0.35,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(height: height * 0.005),
                  ShimmerLine(
                    height: height * 0.0175,
                    width: width * 0.25,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
              ShimmerBox(
                height: height * 0.06,
                width: height * 0.06,
                radius: width * 0.133,
                color: Colors.grey.shade300,
              ),
            ],
          ),
          SizedBox(height: height * 0.025),
          ShimmerLine(
            height: height * 0.0125,
            width: width,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: height * 0.015),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerLine(
                height: height * 0.015,
                width: width * 0.2,
                color: Colors.grey.shade300,
              ),
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

  Widget _challengeBanner(double width, double height) {
    return Container(
      height: height * 0.15,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandPurple.withValues(alpha: 0.1),
            AppColors.brandPurple.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(width * 0.056),
      ),
      padding: EdgeInsets.all(width * 0.044),
      child: Row(
        children: [
          ShimmerBox(
            height: height * 0.08,
            width: height * 0.08,
            radius: width * 0.178,
            color: Colors.grey.shade300,
          ),
          SizedBox(width: width * 0.044),
          SizedBox(
            width: width * 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShimmerLine(
                  height: height * 0.0225,
                  width: width * 0.4,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: height * 0.01),
                ShimmerLine(
                  height: height * 0.0175,
                  width: width * 0.6,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _routineCard(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.044),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          ShimmerBox(
            height: height * 0.04,
            width: height * 0.065,
            radius: width * 0.133,
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
                  width: width * 0.5,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: height * 0.008),
                ShimmerLine(
                  height: height * 0.015,
                  width: width * 0.7,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
          ShimmerBox(
            height: height * 0.035,
            width: height * 0.035,
            radius: width * 0.156,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _infoCard(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.044),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.044),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          ShimmerBox(
            height: height * 0.055,
            width: height * 0.055,
            radius: width * 0.133,
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
                  width: width * 0.45,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: height * 0.008),
                ShimmerLine(
                  height: height * 0.015,
                  width: width * 0.65,
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
