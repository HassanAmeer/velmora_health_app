import 'package:flutter/material.dart';
import 'shimmer_widget.dart';

import '../../../constants/app_colors.dart';

class ChatScreenSkeleton extends StatelessWidget {
  const ChatScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;

    return ShimmerWrap(
      Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Chat messages
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  width * 0.056,
                  height * 0.03,
                  width * 0.056,
                  height * 0.025,
                ),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // AI greeting
                  _aiMessage(width, height),
                  SizedBox(height: height * 0.02),
                  _userMessage(width, height),
                  SizedBox(height: height * 0.02),
                  _aiMessage(width, height),
                  SizedBox(height: height * 0.02),
                  _userMessage(width, height),
                  SizedBox(height: height * 0.02),
                  _aiMessage(width, height),
                ],
              ),
            ),
            // Disclaimer
            _disclaimer(width, height),
            // Input field
            // _inputField(width, height),
          ],
        ),
      ),
    );
  }

  Widget _aiMessage(double width, double height) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(
          height: height * 0.05,
          width: height * 0.05,
          radius: width * 0.056,
          color: AppColors.brandPurple.withValues(alpha: 0.2),
        ),
        SizedBox(width: width * 0.033),
        Flexible(
          child: Container(
            padding: EdgeInsets.all(width * 0.044),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F9),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(width * 0.056),
                bottomLeft: Radius.circular(width * 0.056),
                bottomRight: Radius.circular(width * 0.056),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLine(
                  height: height * 0.0175,
                  width: width * 0.6,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: height * 0.01),
                ShimmerLine(
                  height: height * 0.0175,
                  width: width * 0.8,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: height * 0.01),
                ShimmerLine(
                  height: height * 0.0175,
                  width: width * 0.4,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _userMessage(double width, double height) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.all(width * 0.044),
            decoration: BoxDecoration(
              color: AppColors.brandPurple,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(width * 0.056),
                bottomLeft: Radius.circular(width * 0.056),
                bottomRight: Radius.circular(width * 0.056),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLine(
                  height: height * 0.0175,
                  width: width * 0.5,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                SizedBox(height: height * 0.01),
                ShimmerLine(
                  height: height * 0.0175,
                  width: width * 0.7,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: width * 0.033),
        ShimmerBox(
          height: height * 0.05,
          width: height * 0.05,
          radius: width * 0.056,
          color: AppColors.brandPurple,
        ),
      ],
    );
  }

  Widget _disclaimer(double width, double height) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(width * 0.033),
      margin: EdgeInsets.only(bottom: height * 0.02),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(width * 0.033),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        children: [
          ShimmerBox(
            height: height * 0.0225,
            width: height * 0.0225,
            radius: width * 0.05,
            color: Colors.orange,
          ),
          SizedBox(width: width * 0.022),
          SizedBox(
            width: width * 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLine(
                  height: height * 0.015,
                  width: width * 0.8,
                  color: Colors.orange.shade300,
                ),
                SizedBox(height: height * 0.005),
                ShimmerLine(
                  height: height * 0.015,
                  width: width * 0.6,
                  color: Colors.orange.shade300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(double width, double height) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        width * 0.056,
        0,
        width * 0.056,
        height * 0.006,
      ),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          SizedBox(
            width: width * 0.4,
            child: Container(
              height: height * 0.0675,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F9),
                borderRadius: BorderRadius.circular(width * 0.042),
              ),
            ),
          ),
          SizedBox(width: width * 0.033),
          ShimmerBox(
            height: height * 0.0675,
            width: height * 0.0675,
            radius: width * 0.15,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
