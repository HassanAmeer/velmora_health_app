import 'package:velmora/main.dart';
import 'package:velmora/constants/app_colors.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/screens/auth/sign_in_screen.dart';
import 'package:velmora/screens/settings/account_screen.dart';
import 'package:velmora/screens/settings/help_support_screen.dart';
import 'package:velmora/screens/settings/notifications_screen.dart';
import 'package:velmora/screens/settings/privacy_security_screen.dart';
import 'package:velmora/screens/settings/subscription_screen.dart';
import 'package:velmora/services/auth_service.dart';
import 'package:velmora/services/subscription_service.dart';
import 'package:velmora/services/user_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/widgets/skeletons/settings_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();

  // Track selected language CODE ('en', 'ar', 'fr')
  String _selectedLanguage = "en";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserLanguage();
  }

  /// Load user's preferred language from Firebase
  Future<void> _loadUserLanguage() async {
    try {
      final userData = await _userService.getUserData();
      if (userData != null && mounted) {
        final languageCode = userData['preferredLanguage'] as String?;
        if (languageCode != null) {
          setState(() {
            _selectedLanguage = languageCode; // store the code directly
          });
        }
      }
    } catch (e) {
      // Use default if error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Convert language code to display name (locale-aware)
  String _getLanguageName(String code, AppLocalizations l10n) {
    switch (code) {
      case 'en':
        return l10n.english;
      case 'ar':
        return l10n.arabic;
      case 'fr':
        return l10n.french;
      default:
        return l10n.english;
    }
  }

  /// Convert display name to language code
  String _getLanguageCode(String name, AppLocalizations l10n) {
    if (name == l10n.arabic) return 'ar';
    if (name == l10n.french) return 'fr';
    return 'en';
  }

  /// Save language to Firebase
  Future<void> _saveLanguage(String languageCode) async {
    try {
      await _userService.updateLanguage(languageCode);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.somethingWentWrong}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  final subscriptionService = SubscriptionService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: _isLoading
          ? const SettingsScreenSkeleton()
          : Column(
              children: [
                _buildHeader(l10n),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 15.h,
                    ),
                    children: [
                      _buildSettingsGroup([
                        _buildSettingsItem(
                          icon: Icons.person_outline,
                          title: l10n.account,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AccountScreen(),
                              ),
                            );
                          },
                        ),
                        // Check if user has active subscription
                        _buildSettingsItem(
                          icon: Icons.credit_card_outlined,
                          title: l10n.subscription,
                          onTap: () async {
                            final hasSubscription = await subscriptionService
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
                        ),
                      ]),
                      SizedBox(height: 20.h),
                      _buildSettingsGroup([
                        _buildSettingsItem(
                          icon: Icons.language_outlined,
                          title: _getLanguageName(_selectedLanguage, l10n),
                          onTap: () => _showLanguageDialog(context, l10n),
                        ),
                        _buildSettingsItem(
                          icon: Icons.notifications_none_outlined,
                          title: l10n.notifications,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingsItem(
                          icon: Icons.shield_outlined,
                          title: l10n.privacySecurity,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PrivacySecurityScreen(),
                              ),
                            );
                          },
                        ),
                      ]),
                      SizedBox(height: 20.h),
                      _buildSettingsGroup([
                        _buildSettingsItem(
                          icon: Icons.help_outline_rounded,
                          title: l10n.helpSupport,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpSupportScreen(),
                              ),
                            );
                          },
                        ),
                      ]),
                      SizedBox(height: 20.h),
                      _buildSettingsGroup([
                        _buildSettingsItem(
                          icon: Icons.logout_rounded,
                          title: l10n.logout,
                          isDestructive: true,
                          onTap: () => _handleLogout(context, l10n),
                        ),
                      ]),
                      SizedBox(height: 100.h),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // --- Enhanced Logout Logic ---
  Future<void> _handleLogout(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
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
                // Branded Icon/Logo
                Container(
                  padding: EdgeInsets.all(20.adaptSize),
                  decoration: BoxDecoration(
                    color: AppColors.brandPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Image.asset(
                            'assets/splash_logo.png',
                            width: 60.adaptSize,
                            color: AppColors.brandPurple,
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
                  l10n.logoutMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.fSize,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 32.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            fontSize: 16.fSize,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n.logout,
                          style: TextStyle(
                            fontSize: 16.fSize,
                            fontWeight: FontWeight.bold,
                          ),
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

    if (confirm == true) {
      final authService = AuthService();
      try {
        await authService.logout();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LogInScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // --- Language Popup Logic ---
  void _showLanguageDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.adaptSize),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24),
                    Text(
                      l10n.settings, // Reuse settings title or add 'language' key
                      style: TextStyle(
                        fontSize: 18.fSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2933),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                _buildLanguageOption(l10n.english, 'en', l10n.english, l10n),
                _buildLanguageOption(l10n.arabic, 'ar', l10n.arabic, l10n),
                _buildLanguageOption(l10n.french, 'fr', l10n.french, l10n),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    String title,
    String code,
    String subTitle,
    AppLocalizations l10n,
  ) {
    bool isSelected = _selectedLanguage == code;
    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedLanguage = code;
        });
        MyApp.setLocale(context, Locale(code, ''));
        await _saveLanguage(code); // Save to Firebase with code directly
        if (mounted) Navigator.pop(context);
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPurple.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? AppColors.brandPurple : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.fSize,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                Text(
                  subTitle,
                  style: TextStyle(fontSize: 12.fSize, color: Colors.grey),
                ),
              ],
            ),
            if (isSelected)
              const CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.brandPurple,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Rest of your original UI Methods ---
  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: 180.h,
      decoration: const BoxDecoration(
        color: AppColors.brandPurple,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 80.h, 24.w, 0),
      child: Text(
        l10n.settings,
        style: TextStyle(
          fontSize: 32.fSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.adaptSize),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final Color themeColor = isDestructive ? Colors.red : AppColors.brandPurple;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.adaptSize),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.adaptSize),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.adaptSize),
              ),
              child: Icon(icon, color: themeColor, size: 22.adaptSize),
            ),
            SizedBox(width: 16.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 15.fSize,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.red : const Color(0xFF1F2933),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 24.adaptSize,
            ),
          ],
        ),
      ),
    );
  }
}
