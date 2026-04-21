import 'package:flutter/material.dart';
import 'shimmer_widget.dart';

import '../../../constants/app_colors.dart';

class KegelAchievementsSkeleton extends StatelessWidget {
  const KegelAchievementsSkeleton({super.key});

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
          // Content
          SizedBox(
            height: height * 0.65,
            child: ListView(
              padding: EdgeInsets.all(width * 0.056),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Stats cards
                Row(
                  children: [
                    _statCard(width, height),
                    SizedBox(width: width * 0.033),
                    _statCard(width, height),
                  ],
                ),
                SizedBox(height: height * 0.03),
                // Weekly chart
                _weeklyChart(width, height),
                SizedBox(height: height * 0.03),
                // Achievements title
                ShimmerLine(
                  height: height * 0.0225,
                  width: width * 0.35,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: height * 0.02),
                // Achievement rows
                ...List.generate(
                  6,
                  (_) => Padding(
                    padding: EdgeInsets.only(bottom: height * 0.015),
                    child: _achievementRow(width, height),
                  ),
                ),
                SizedBox(height: height * 0.03),
                // 30-day plan
                ShimmerLine(
                  height: height * 0.0225,
                  width: width * 0.35,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: height * 0.02),
                _planCard(width, height),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(double width, double height) {
    return SizedBox(
      width: width * 0.4,
      child: Container(
        padding: EdgeInsets.all(width * 0.044),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(width * 0.044),
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
            ShimmerBox(
              height: height * 0.05,
              width: height * 0.05,
              radius: width * 0.11,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: height * 0.015),
            ShimmerLine(
              height: height * 0.03,
              width: width * 0.5,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: height * 0.005),
            ShimmerLine(
              height: height * 0.015,
              width: width * 0.35,
              color: Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _weeklyChart(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.044),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.044),
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
          ShimmerLine(
            height: height * 0.019,
            width: width * 0.3,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: height * 0.025),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final h = [
                height * 0.05,
                height * 0.075,
                height * 0.0375,
                height * 0.1,
                height * 0.0625,
                height * 0.0875,
                height * 0.056,
              ][i];
              return ShimmerBox(
                height: h,
                width: width * 0.067,
                radius: width * 0.067,
                color: Colors.grey.shade300,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _achievementRow(double width, double height) {
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
            height: height * 0.0625,
            width: height * 0.0625,
            radius: width * 0.139,
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
          SizedBox(width: width * 0.022),
          ShimmerBox(
            height: height * 0.045,
            width: height * 0.045,
            radius: width * 0.1,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _planCard(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.044),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.044),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          ShimmerLine(
            height: height * 0.02,
            width: width * 0.4,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: height * 0.02),
          ...List.generate(
            4,
            (_) => Padding(
              padding: EdgeInsets.only(bottom: height * 0.015),
              child: Row(
                children: [
                  ShimmerBox(
                    height: height * 0.045,
                    width: height * 0.045,
                    radius: width * 0.089,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(width: width * 0.033),
                  SizedBox(
                    width: width * 0.55,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLine(
                          height: height * 0.0175,
                          width: width * 0.4,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: height * 0.005),
                        ShimmerLine(
                          height: height * 0.014,
                          width: width * 0.6,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: width * 0.022),
                  ShimmerBox(
                    height: height * 0.025,
                    width: height * 0.025,
                    radius: width * 0.133,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
