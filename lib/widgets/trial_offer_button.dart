import 'package:flutter/material.dart';
import 'package:velmora/constants/app_colors.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/screens/settings/subscription_screen.dart';
import 'package:velmora/services/user_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';

class TrialOfferButton extends StatefulWidget {
  final bool isFromPremiumScreen;
  final VoidCallback? onTrialStarted;
  final String? customText;

  const TrialOfferButton({
    super.key,
    this.isFromPremiumScreen = false,
    this.onTrialStarted,
    this.customText,
  });

  @override
  State<TrialOfferButton> createState() => _TrialOfferButtonState();
}

class _TrialOfferButtonState extends State<TrialOfferButton> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  bool _hasUsedTrial = false;
  bool _isTrialActive = false;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _checkTrialStatus();
  }

  Future<void> _checkTrialStatus() async {
    try {
      final hasUsed = await _userService.hasUsedTrial();
      final isActive = await _userService.isTrialActive();
      if (mounted) {
        setState(() {
          _hasUsedTrial = hasUsed;
          _isTrialActive = isActive;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startFreeTrial() async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);
    try {
      await _userService.startTrial();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).trialStarted),
            backgroundColor: Colors.green,
          ),
        );
        if (widget.onTrialStarted != null) {
          widget.onTrialStarted!();
        } else if (widget.isFromPremiumScreen) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: SizedBox(
          height: 20.adaptSize,
          width: 20.adaptSize,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.brandPurple,
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    final text =
        widget.customText ?? l10n.translate('start_48_hour_free_trial');

    if (_hasUsedTrial || _isTrialActive) {
      // Disabled state with strikethrough
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16.fSize,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.lineThrough,
            decorationColor: Colors.grey,
            decorationThickness: 2,
          ),
        ),
      );
    }

    // Enabled state
    return TextButton(
      onPressed: _isPurchasing
          ? null
          : () {
              if (widget.isFromPremiumScreen) {
                // If we are already on the premium screen, start the trial
                _startFreeTrial();
              } else {
                // Navigate to subscription screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PremiumScreen(),
                  ),
                ).then((_) {
                  _checkTrialStatus();
                });
              }
            },
      child: _isPurchasing
          ? SizedBox(
              height: 20.adaptSize,
              width: 20.adaptSize,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.brandPurple,
              ),
            )
          : Text(
              text,
              style: TextStyle(
                fontSize: 16.fSize,
                color: AppColors.brandPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
    );
  }
}
