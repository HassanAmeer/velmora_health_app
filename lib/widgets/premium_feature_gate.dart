import 'package:velmora/constants/app_colors.dart';
import 'package:velmora/screens/settings/subscription_screen.dart';
import 'package:velmora/services/subscription_service.dart';
import 'package:velmora/services/user_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/widgets/app_loading_widgets.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/widgets/trial_offer_button.dart';
import 'package:velmora/widgets/bottom_nav_bar_widget.dart';
import 'package:flutter/material.dart';

/// Widget that gates premium features and shows upgrade prompt
class PremiumFeatureGate extends StatelessWidget {
  final Widget child;
  final String featureName;
  final VoidCallback? onBackToHome;

  const PremiumFeatureGate({
    super.key,
    required this.child,
    required this.featureName,
    this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAccess(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: AppCircularLoader());
        }

        final hasAccess = snapshot.data ?? false;

        if (hasAccess) {
          return child;
        }

        return _buildLockedScreen(context);
      },
    );
  }

  Future<bool> _checkAccess() async {
    final subscriptionService = SubscriptionService();
    final userService = UserService();

    // Check if user has active subscription
    final hasSubscription = await subscriptionService.hasActiveSubscription();
    if (hasSubscription) return true;

    // Check if user is in trial
    final isTrialActive = await userService.isTrialActive();
    return isTrialActive;
  }

  Widget _buildLockedScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFF),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 24.adaptSize),
          onPressed: () {
            if (onBackToHome != null) {
              onBackToHome!();
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const BottomNavBarWidget(),
                ),
                (route) => false,
              );
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.adaptSize),
          child: Column(
            children: [
              SizedBox(height: 40.h),
              // Lock Icon
              Container(
                padding: EdgeInsets.all(24.adaptSize),
                decoration: BoxDecoration(
                  color: AppColors.brandPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 80.adaptSize,
                  color: AppColors.brandPurple,
                ),
              ),

              SizedBox(height: 32.h),

              // Title
              Text(
                l10n.premiumFeature,
                style: TextStyle(
                  fontSize: 28.fSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D1160),
                ),
              ),

              SizedBox(height: 16.h),

              // Description
              Text(
                '$featureName ${l10n.translate('is_a_premium_feature_upgrade_to_unlock_full_access')}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.fSize,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              SizedBox(height: 48.h),

              // Upgrade Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PremiumScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.adaptSize),
                    ),
                  ),
                  child: Text(
                    l10n.translate('upgrade_to_premium'),
                    style: TextStyle(
                      fontSize: 18.fSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Start Trial Button
              const TrialOfferButton(),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
