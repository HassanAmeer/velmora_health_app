import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velmora/main.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/screens/chat/chat_screen.dart';
import 'package:velmora/screens/game/gamescreen.dart';
import 'package:velmora/screens/kegel/kegel_screen.dart';
import 'package:velmora/screens/settings/subscription_screen.dart';
import 'package:velmora/services/auth_service.dart';
import 'package:velmora/services/subscription_service.dart';
import 'package:velmora/services/user_service.dart';
import 'package:velmora/widgets/skeletons/home_skeleton.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../services/get_live_notification.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  String _displayName = '';
  String _subscriptionStatus = 'free';
  Duration? _trialTimeRemaining;
  String _preferredLanguage = 'EN';
  bool _isLoading = true;
  String _subscriptionType = '';
  DateTime? _subscriptionExpiryDate;
  bool _hasUsedTrial = false;

  @override
  void initState() {
    super.initState();
    Notify().requestNotifyPermissionF(); // for permssions
    Notify().listenBackgroundNotification();
    Notify().listenNotificationOnOpendApp();
    Notify().onClickFcmNotifi();
    Notify().getTokenF();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _userService.getUserData();
      if (userData != null && mounted) {
        setState(() {
          _displayName = userData['displayName'] ?? '';
          _subscriptionStatus = userData['subscriptionStatus'] ?? 'free';
          _preferredLanguage = (userData['preferredLanguage'] ?? 'en')
              .toUpperCase();
          _subscriptionType = userData['subscriptionType'] ?? '';

          // Get expiry date
          final expiryTimestamp = userData['subscriptionExpiryDate'];
          if (expiryTimestamp != null && expiryTimestamp is Timestamp) {
            _subscriptionExpiryDate = expiryTimestamp.toDate();
          }
        });

        // Check trial status
        final isTrialActive = await _userService.isTrialActive();
        final hasUsedTrial = await _userService.hasUsedTrial();

        if (mounted) {
          setState(() {
            _hasUsedTrial = hasUsedTrial;
          });
        }

        if (isTrialActive) {
          final remaining = await _userService.getTrialTimeRemaining();
          if (mounted) {
            setState(() {
              _subscriptionStatus = 'trial';
              _trialTimeRemaining = remaining;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startTrial() async {
    try {
      await _userService.startTrial();
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).trialStarted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).failedToStartTrial}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changeLanguage(String lang) async {
    final langCode = lang.substring(0, 2).toLowerCase();
    try {
      await _userService.updateLanguage(langCode);
      setState(() {
        _preferredLanguage = lang;
      });
      if (mounted) {
        MyApp.setLocale(context, Locale(langCode, ''));
      }
    } catch (e) {
      debugPrint('Error updating language: $e');
    }
  }

  void _navigateToFeature(String feature) {
    int? tabIndex;
    switch (feature) {
      case 'games':
        tabIndex = 1;
        break;
      case 'kegel':
        tabIndex = 2;
        break;
      case 'chat':
        tabIndex = 3;
        break;
      default:
        return;
    }

    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(tabIndex);
      return;
    }

    Widget screen;
    switch (feature) {
      case 'games':
        screen = const GamesScreen();
        break;
      case 'kegel':
        screen = const KegelScreen();
        break;
      case 'chat':
        screen = const ChatScreen();
        break;
      default:
        return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  String _getWelcomeMessage() {
    if (_displayName.isEmpty) {
      return AppLocalizations.of(context).welcomeBack;
    }
    return '${AppLocalizations.of(context).welcome}\n$_displayName';
  }

  String _getTrialMessage() {
    if (_subscriptionStatus == 'trial' && _trialTimeRemaining != null) {
      final hours = _trialTimeRemaining!.inHours;
      final minutes = _trialTimeRemaining!.inMinutes % 60;
      return '$hours:${minutes.toString().padLeft(2, '0')} ${AppLocalizations.of(context).hoursRemaining}';
    }
    if (_subscriptionStatus == 'premium') {
      // Show plan type
      String planType = 'Premium';
      if (_subscriptionType.contains('monthly')) {
        planType = 'Monthly Premium';
      } else if (_subscriptionType.contains('quarterly')) {
        planType = 'Quarterly Premium';
      } else if (_subscriptionType.contains('yearly')) {
        planType = 'Yearly Premium';
      }
      return planType;
    }
    return AppLocalizations.of(context).fullAccess;
  }

  String _getExpiryMessage() {
    if (_subscriptionStatus == 'premium' && _subscriptionExpiryDate != null) {
      return 'Expiry: ${DateFormat('MMM dd, yyyy').format(_subscriptionExpiryDate!)}';
    }
    return '';
  }

  Future<bool> _showExitConfirmationDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24.adaptSize),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20.adaptSize),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B42FF).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Image.asset(
                            'assets/splash_logo.png',
                            width: 60.adaptSize,
                            color: const Color(0xFF8B42FF),
                            colorBlendMode: BlendMode.srcIn,
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                            color: Colors.yellow.withValues(alpha: 0.5),
                            duration: const Duration(seconds: 2),
                          ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Exit App',
                  style: TextStyle(
                    fontSize: 22.fSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D1160),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Do you want to exit the app?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.fSize,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 32.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16.fSize,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child:
                            Text(
                                  'Exit',
                                  style: TextStyle(
                                    fontSize: 16.fSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                .animate(
                                  onPlay: (controller) => controller.repeat(),
                                )
                                .shimmer(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.7,
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return shouldExit ?? false;
  }

  final subscriptionService = SubscriptionService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Theme Colors
    const Color primaryPurple = Color(0xFF8B42FF);
    const Color trialOrange = Color(0xFFFF8C00);
    const Color lightBackground = Color(0xFFF9F9FF);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await _showExitConfirmationDialog();
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: lightBackground,
        body: _isLoading
            ? const HomeScreenSkeleton()
            : StreamBuilder<DocumentSnapshot?>(
                stream: _userService.userStream,
                builder: (context, snapshot) {
                  // Reload data when Firestore updates
                  if (snapshot.hasData && snapshot.data != null) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data != null) {
                      _displayName = data['displayName'] ?? '';
                      _subscriptionStatus =
                          data['subscriptionStatus'] ?? 'free';
                      _preferredLanguage = (data['preferredLanguage'] ?? 'en')
                          .toUpperCase();
                      _subscriptionType = data['subscriptionType'] ?? '';

                      // Get expiry date
                      final expiryTimestamp = data['subscriptionExpiryDate'];
                      if (expiryTimestamp != null &&
                          expiryTimestamp is Timestamp) {
                        _subscriptionExpiryDate = expiryTimestamp.toDate();
                      }
                    }
                  }

                  return Column(
                    children: [
                      // ── Header & Trial Card Stack ──────────────────────────────
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Purple Header
                          Container(
                            width: double.infinity,
                            height: 260.h,
                            decoration: const BoxDecoration(
                              color: primaryPurple,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(40),
                                bottomRight: Radius.circular(40),
                              ),
                            ),
                            padding: EdgeInsets.fromLTRB(10.w, 60.h, 10.w, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.favorite,
                                          color: Colors.white,
                                          size: 25,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          _getWelcomeMessage(),
                                          style: TextStyle(
                                            fontSize: 18.fSize,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                            height: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Right actions: Bell + Language Switcher
                                    Row(
                                      children: [
                                        SizedBox(width: 8.w),
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              _buildLangChip(
                                                '🇺🇸 EN',
                                                _preferredLanguage == 'EN',
                                                'EN',
                                              ),
                                              _buildLangChip(
                                                '🇸🇦 AR',
                                                _preferredLanguage == 'AR',
                                                'AR',
                                              ),
                                              _buildLangChip(
                                                '🇫🇷 FR',
                                                _preferredLanguage == 'FR',
                                                'FR',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.07,
                                ),
                                Text(
                                  AppLocalizations.of(context).exploreFeatures,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16.fSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Floating Trial Card
                          Positioned(
                            bottom: -45.h,
                            left: 24.w,
                            right: 24.w,
                            child: GestureDetector(
                              onTap: () async {
                                // Always navigate to purchase screen
                                final hasSubscription =
                                    await subscriptionService
                                        .hasActiveSubscription();
                                final snackBar = SnackBar(
                                  backgroundColor: Colors.green,
                                  content: const Text(
                                    'You already have a subscription',
                                  ),
                                );
                                hasSubscription
                                    ? ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(snackBar)
                                    : Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const PremiumScreen(),
                                        ),
                                      );
                              },
                              child: Container(
                                height: 90.h,
                                decoration: BoxDecoration(
                                  color: _subscriptionStatus == 'premium'
                                      ? Colors.green
                                      : (_subscriptionStatus == 'trial' ||
                                            (!_hasUsedTrial &&
                                                _subscriptionStatus == 'free'))
                                      ? trialOrange
                                      : primaryPurple,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                child: Row(
                                  children: [
                                    Icon(
                                      _subscriptionStatus == 'premium'
                                          ? Icons.workspace_premium
                                          : Icons.auto_awesome,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    SizedBox(width: 15.w),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _subscriptionStatus == 'premium'
                                                ? AppLocalizations.of(
                                                    context,
                                                  ).premiumActive
                                                : _subscriptionStatus == 'trial'
                                                ? AppLocalizations.of(
                                                    context,
                                                  ).trialActive
                                                : !_hasUsedTrial
                                                ? AppLocalizations.of(
                                                    context,
                                                  ).startTrial
                                                : 'Free Plan',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16.fSize,
                                            ),
                                          ),
                                          Text(
                                            _subscriptionStatus == 'trial'
                                                ? _getTrialMessage()
                                                : _subscriptionStatus ==
                                                      'premium'
                                                ? _getTrialMessage()
                                                : !_hasUsedTrial
                                                ? '48 hours free access'
                                                : 'Tap to upgrade',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13.fSize,
                                            ),
                                          ),
                                          if (_subscriptionStatus ==
                                                  'premium' &&
                                              _getExpiryMessage()
                                                  .isNotEmpty) ...[
                                            SizedBox(height: 2.h),
                                            Text(
                                              _getExpiryMessage(),
                                              style: TextStyle(
                                                color: Colors.grey.shade300,
                                                fontSize: 11.fSize,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      _subscriptionStatus == 'premium'
                                          ? Icons.verified
                                          : (_subscriptionStatus == 'trial' ||
                                                (!_hasUsedTrial &&
                                                    _subscriptionStatus ==
                                                        'free'))
                                          ? Icons.workspace_premium
                                          : Icons.workspace_premium,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 60.h),

                      // ── Feature List ───────────────────────────────────────────
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          children: [
                            SizedBox(height: 16.h),

                            _buildFeatureCard(
                              title: AppLocalizations.of(context).couplesGames,
                              subtitle: AppLocalizations.of(
                                context,
                              ).couplesGamesSubtitle,
                              icon: Icons.sports_esports,
                              iconBg: const Color(0xFFFF4D8D),
                              onTap: () => _navigateToFeature('games'),
                            ),
                            _buildFeatureCard(
                              title: AppLocalizations.of(
                                context,
                              ).kegelExercises,
                              subtitle: AppLocalizations.of(
                                context,
                              ).kegelExercisesSubtitle,
                              icon: Icons.show_chart,
                              iconBg: const Color(0xFF9E64FF),
                              onTap: () => _navigateToFeature('kegel'),
                            ),
                            _buildFeatureCard(
                              title: AppLocalizations.of(context).aiChatTitle,
                              subtitle: AppLocalizations.of(
                                context,
                              ).aiChatSubtitle,
                              icon: Icons.chat_bubble_outline,
                              iconBg: const Color(0xFF6B66FF),
                              onTap: () => _navigateToFeature('chat'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildLangChip(String label, bool isSelected, String langCode) {
    return GestureDetector(
      onTap: () => _changeLanguage(langCode),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 10.fSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.adaptSize),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: iconBg.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.adaptSize),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.fSize,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey, fontSize: 13.fSize),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
