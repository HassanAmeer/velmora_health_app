import 'package:flutter/material.dart';
import 'shimmer_widget.dart';

class AccountScreenSkeleton extends StatelessWidget {
  const AccountScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;

    return ShimmerWrap(
      Column(
        children: [
          // Form content
          SizedBox(
            height: height * 0.65,
            child: ListView(
              padding: EdgeInsets.all(width * 0.067),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Avatar
                Center(
                  child: ShimmerBox(
                    height: height * 0.125,
                    width: height * 0.125,
                    radius: width * 0.278,
                    color: Colors.grey.shade300,
                  ),
                ),
                SizedBox(height: height * 0.03),
                // Form card
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
                    children: [
                      _formField(width, height),
                      SizedBox(height: height * 0.02),
                      _formField(width, height),
                      SizedBox(height: height * 0.02),
                      _formField(width, height),
                      SizedBox(height: height * 0.04),
                      ShimmerBox(
                        height: height * 0.0625,
                        width: height * 0.6,
                        radius: width,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(height: height * 0.02),
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

  Widget _formField(double width, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerLine(
          height: height * 0.015,
          width: width * 0.25,
          color: Colors.grey.shade300,
        ),
        SizedBox(height: height * 0.01),
        Container(
          height: height * 0.0625,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(width * 0.028),
          ),
        ),
      ],
    );
  }
}
