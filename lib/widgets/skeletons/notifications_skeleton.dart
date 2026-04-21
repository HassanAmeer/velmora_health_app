import 'package:flutter/material.dart';
import 'shimmer_widget.dart';

class NotificationsScreenSkeleton extends StatelessWidget {
  const NotificationsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;

    return ShimmerWrap(
      Column(
        children: [
          // Notifications list
          SizedBox(
            height: height * 0.65,
            child: ListView(
              padding: EdgeInsets.all(width * 0.04),
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(
                5,
                (_) => Padding(
                  padding: EdgeInsets.only(bottom: height * 0.015),
                  child: _notificationCard(width, height),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
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
      child: Row(
        children: [
          ShimmerBox(
            height: height * 0.05,
            width: height * 0.05,
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
                  width: width * 0.8,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: height * 0.005),
                ShimmerLine(
                  height: height * 0.012,
                  width: width * 0.3,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
          SizedBox(width: width * 0.022),
          ShimmerBox(
            height: height * 0.035,
            width: height * 0.035,
            radius: width * 0.067,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
