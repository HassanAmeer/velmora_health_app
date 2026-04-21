import 'package:flutter/material.dart';
import 'shimmer_widget.dart';

import '../../../constants/app_colors.dart';

class KegelChallengeSkeleton extends StatelessWidget {
  const KegelChallengeSkeleton({super.key});

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
              padding: EdgeInsets.all(width * 0.056),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Header card
                _headerCard(width, height),
                SizedBox(height: height * 0.03),
                ShimmerLine(
                  height: height * 0.0225,
                  width: width * 0.35,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: height * 0.02),
                // Progress grid
                _progressGrid(width, height),
                SizedBox(height: height * 0.03),
                // Week cards
                _weekCard(width, height),
                SizedBox(height: height * 0.015),
                _weekCard(width, height),
                SizedBox(height: height * 0.015),
                _weekCard(width, height),
                SizedBox(height: height * 0.015),
                _weekCard(width, height),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCard(double width, double height) {
    return Container(
      width: double.infinity,
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLine(
                    height: height * 0.0225,
                    width: width * 0.4,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(height: height * 0.005),
                  ShimmerLine(
                    height: height * 0.0175,
                    width: width * 0.3,
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
          Container(
            height: height * 0.0125,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(height * 0.00625),
            ),
          ),
          SizedBox(height: height * 0.015),
          ShimmerLine(
            height: height * 0.016,
            width: width * 0.5,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _progressGrid(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.044),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.056),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          crossAxisSpacing: width * 0.028,
          mainAxisSpacing: height * 0.0125,
        ),
        itemCount: 30,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(width * 0.028),
            ),
          );
        },
      ),
    );
  }

  Widget _weekCard(double width, double height) {
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
            height: height * 0.06,
            width: height * 0.06,
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
                  height: height * 0.019,
                  width: width * 0.45,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: height * 0.0025),
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
            height: height * 0.028,
            width: height * 0.028,
            radius: width * 0.156,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
