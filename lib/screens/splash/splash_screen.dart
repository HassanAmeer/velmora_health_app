import 'dart:async';
import 'package:velmora/screens/onboarding/onboarding_screen.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Initialize Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1500,
      ), // Adjust speed of appearance
    );

    // 2. Define Fade-in Animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // 3. Start Animation
    _controller.forward();

    // 4. Navigate to next screen after delay
    Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      // Replace with your home route
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.deepPurpleAccent, // Clean white background
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your Logo from the screenshot
              Image.asset(
                    'assets/splash_logo.png',
                    width: MediaQuery.of(context).size.width * 0.5,
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    color: Colors.yellow,
                    duration: const Duration(milliseconds: 1500),
                  ),
              const SizedBox(height: 30),

              // App Title
              Text(
                "Together",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Deep Purple from image
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 10),

              // Slogan - Localized
              Text(
                    l10n.wellnessForCouples,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70, // Lighter purple/lavender
                      fontWeight: FontWeight.w400,
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    color: Colors.deepPurpleAccent,
                    duration: const Duration(milliseconds: 2500),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
