import 'package:flutter/material.dart';
import 'shimmer_widget.dart';

class LegalScreenSkeleton extends StatelessWidget {
  const LegalScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;

    return ShimmerWrap(
      Column(
        children: [
          // Content
          SizedBox(
            height: height * 0.65,
            child: ListView(
              padding: EdgeInsets.all(width * 0.067),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _legalSection(width, height),
                SizedBox(height: height * 0.03),
                _legalSection(width, height),
                SizedBox(height: height * 0.03),
                _legalSection(width, height),
                SizedBox(height: height * 0.03),
                _legalSection(width, height),
                SizedBox(height: height * 0.03),
                _legalSection(width, height),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legalSection(double width, double height) {
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
            width: width * 0.4,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: height * 0.02),
          ShimmerLine(
            height: height * 0.0175,
            width: width * 0.85,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: height * 0.012),
          ShimmerLine(
            height: height * 0.0175,
            width: width * 0.9,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: height * 0.012),
          ShimmerLine(
            height: height * 0.0175,
            width: width * 0.75,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: height * 0.012),
          ShimmerLine(
            height: height * 0.0175,
            width: width * 0.8,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
