import 'package:velmora/main.dart';
import 'package:velmora/constants/app_colors.dart';
import 'package:velmora/screens/auth/sign_in_screen.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _currentIndex = 0;
  String _selectedLanguage = 'en';

  void _onNextPage(int screenCount) async {
    if (_currentIndex < screenCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      // Save onboarding completion
      await _completeOnboarding();

      // Navigate to Sign In
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LogInScreen()),
        );
      }
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      await prefs.setString('preferred_language', _selectedLanguage);

      // If user is logged in, save to Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'onboardingCompleted': true,
          'preferredLanguage': _selectedLanguage,
          'onboardingCompletedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
    }
  }

  void _skipOnboarding() async {
    await _completeOnboarding();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LogInScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final List<OnboardingData> screens = [
      OnboardingData(
        title: l10n.onboardingTitle1,
        subtitle: l10n.onboardingDesc1,
        icon: Icons.favorite_rounded,
        color: AppColors.onboarding1,
      ),
      OnboardingData(
        title: l10n.onboardingTitle2,
        subtitle: l10n.onboardingDesc2,
        icon: Icons.people_rounded,
        color: AppColors.onboarding2,
      ),
      OnboardingData(
        title: l10n.onboardingTitle3,
        subtitle: l10n.onboardingDesc3,
        icon: Icons.auto_awesome_rounded,
        color: AppColors.onboarding3,
      ),
      OnboardingData(
        title: l10n.onboardingTitle4,
        subtitle: l10n.onboardingDesc4,
        icon: Icons.language_rounded,
        color: AppColors.brandPurple,
        isLanguageSelection: true,
        isLast: true,
      ),
    ];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        color: screens[_currentIndex].color,
        child: SafeArea(
          child: Column(
            children: [
              // Skip Button
              if (_currentIndex < screens.length - 1)
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      l10n.skip,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemCount: screens.length,
                  itemBuilder: (context, index) {
                    if (screens[index].isLanguageSelection) {
                      return _buildLanguageSelection(l10n);
                    }
                    return OnboardingContent(data: screens[index]);
                  },
                ),
              ),

              // Bottom Section: Indicator & Button
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    // Dot Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        screens.length,
                        (index) => _buildDot(index, screens.length),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _onNextPage(screens.length),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: screens[_currentIndex].color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentIndex == screens.length - 1
                                  ? l10n.getStarted
                                  : l10n.continueText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index, int screenCount) {
    bool isActive = _currentIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white54,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildLanguageSelection(AppLocalizations l10n) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              Icons.language_rounded,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            l10n.onboardingTitle4,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            l10n.onboardingDesc4,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          _buildLanguageOption(l10n.english, 'en', Icons.language),
          const SizedBox(height: 10),
          _buildLanguageOption(l10n.arabic, 'ar', Icons.language),
          const SizedBox(height: 10),
          _buildLanguageOption(l10n.french, 'fr', Icons.language),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String label, String code, IconData icon) {
    final isSelected = _selectedLanguage == code;
    return InkWell(
      onTap: () {
        setState(() => _selectedLanguage = code);
        MyApp.setLocale(context, Locale(code, ''));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.brandPurple : Colors.white,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.brandPurple : Colors.white,
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.brandPurple),
          ],
        ),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final OnboardingData data;
  const OnboardingContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(data.icon, size: 80, color: Colors.white),
          ),
          const SizedBox(height: 60),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isLast;
  final bool isLanguageSelection;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isLast = false,
    this.isLanguageSelection = false,
  });
}
