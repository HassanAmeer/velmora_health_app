import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingIndicatorWideget extends StatelessWidget {
  final Color? color;
  const LoadingIndicatorWideget({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Lottie.asset('assets/json/loader.json', height: 80, width: 80);
    //CircularProgressIndicator(color: color ?? AppColors.primary);
  }
}
