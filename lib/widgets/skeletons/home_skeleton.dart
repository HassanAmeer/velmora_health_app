import 'package:flutter/material.dart';
import 'shimmer_widget.dart';

class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

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
            height: height * 0.2, // 260.h equivalent
            color: Colors.grey.shade300,
            padding: EdgeInsets.fromLTRB(
              width * 0.028,
              height * 0.075,
              width * 0.028,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerBox(
                      height: height * 0.04,
                      width: height * 0.04,
                      radius: width * 0.044,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(width: width * 0.014),
                    ShimmerLine(
                      height: height * 0.025,
                      width: width * 0.35,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
                SizedBox(height: height * 0.025),
                ShimmerLine(
                  height: height * 0.0175,
                  width: width * 0.4,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
          // Floating subscription card
          Padding(
            padding: EdgeInsets.fromLTRB(
              width * 0.067,
              height * 0.015,
              width * 0.067,
              0,
            ),
            child: Container(
              height: height * 0.1125,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(width * 0.056),
              ),
              padding: EdgeInsets.symmetric(horizontal: width * 0.04),
              child: Row(
                children: [
                  ShimmerBox(
                    height: height * 0.035,
                    width: height * 0.035,
                    radius: width * 0.039,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(width: width * 0.042),
                  SizedBox(
                    width: width * 0.55,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLine(
                          height: height * 0.02,
                          width: width * 0.5,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: height * 0.0075),
                        ShimmerLine(
                          height: height * 0.014,
                          width: width * 0.7,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    ),
                  ),
                  ShimmerBox(
                    height: height * 0.04,
                    width: height * 0.04,
                    radius: width * 0.044,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            ),
          ),
          // Feature cards
          SizedBox(
            height: height * 0.5,
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: width * 0.067),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                SizedBox(height: height * 0.02),
                _featureCard(width, height),
                SizedBox(height: height * 0.02),
                _featureCard(width, height),
                SizedBox(height: height * 0.02),
                _featureCard(width, height),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(double width, double height) {
    return _card(
      Colors.white,
      width * 0.044,
      EdgeInsets.all(width * 0.044),
      Row(
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
                  height: height * 0.02,
                  width: width * 0.5,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: height * 0.01),
                ShimmerLine(
                  height: height * 0.015,
                  width: width * 0.8,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Color color, double radius, EdgeInsets padding, Widget child) =>
      Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      );
}
