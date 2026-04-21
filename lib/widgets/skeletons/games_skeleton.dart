import 'package:flutter/material.dart';
import 'shimmer_widget.dart';


class GamesScreenSkeleton extends StatelessWidget {
  const GamesScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;

    return ShimmerWrap(
      Scaffold(
        backgroundColor: const Color(0xFFF9F9FF),
        body: Column(
          children: [
            // Header Match
            Container(
              width: double.infinity,
              height: height * 0.22,
              decoration: const BoxDecoration(
                color: Color(0xFFE91E63),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              padding: EdgeInsets.fromLTRB(width * 0.06, 60, width * 0.06, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_back, color: Colors.white24, size: 24),
                  const SizedBox(height: 20),
                  ShimmerLine(
                    height: height * 0.04,
                    width: width * 0.5,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 8),
                  ShimmerLine(
                    height: height * 0.02,
                    width: width * 0.4,
                    color: Colors.white24,
                  ),
                ],
              ),
            ),

            // Game cards List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(width * 0.06),
                itemCount: 3,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _gameCard(width, height),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameCard(double width, double height) {
    return Container(
      height: height * 0.28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image area
          Container(
            height: height * 0.15,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: const Center(
              child: Icon(Icons.image, color: Colors.white, size: 40),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLine(
                  height: 18,
                  width: width * 0.5,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 10),
                ShimmerLine(
                  height: 14,
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
}
