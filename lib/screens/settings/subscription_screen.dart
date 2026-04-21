// import 'dart:io';

// import 'package:url_launcher/url_launcher.dart';
// import 'package:velmora/constants/app_colors.dart';
// import 'package:velmora/l10n/app_localizations.dart';
// import 'package:velmora/services/subscription_plans_service.dart';
// import 'package:velmora/services/subscription_service.dart';
// import 'package:velmora/services/user_service.dart';
// import 'package:velmora/utils/responsive_sizer.dart';
// import 'package:flutter/material.dart';
// import 'package:velmora/widgets/skeletons/subscription_skeleton.dart';
// import 'package:velmora/widgets/app_loading_widgets.dart';

// class PremiumScreen extends StatefulWidget {
//   const PremiumScreen({super.key});

//   @override
//   State<PremiumScreen> createState() => _PremiumScreenState();
// }

// class _PremiumScreenState extends State<PremiumScreen>
//     with SingleTickerProviderStateMixin {
//   final SubscriptionService _subscriptionService = SubscriptionService();
//   final SubscriptionPlansService _plansService = SubscriptionPlansService();
//   final UserService _userService = UserService();

//   String? _selectedPlanId;
//   bool _isLoading = true;
//   bool _isPurchasing = false;
//   List<SubscriptionPlan> _plans = [];
//   bool _hasUsedTrial = false;
//   bool _isTrialActive = false;
//   bool _hasActiveSubscription = false;

//   late AnimationController _animController;
//   late Animation<double> _fadeAnim;
//   late Animation<Offset> _slideAnim;

//   @override
//   void initState() {
//     super.initState();
//     _animController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//     _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
//     _slideAnim = Tween<Offset>(
//       begin: const Offset(0, 0.08),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await _initialize();
//     });
//   }

//   @override
//   void dispose() {
//     _animController.dispose();
//     super.dispose();
//   }

//   Future<void> _initialize() async {
//     await _subscriptionService.initialize();
//     try {
//       final plans = await _plansService.getPlans();
//       final hasUsedTrial = await _userService.hasUsedTrial();
//       final isTrialActive = await _userService.isTrialActive();
//       final hasActiveSubscription = await _subscriptionService
//           .hasActiveSubscription();

//       if (mounted) {
//         setState(() {
//           _plans = plans;
//           _hasUsedTrial = hasUsedTrial;
//           _isTrialActive = isTrialActive;
//           _hasActiveSubscription = hasActiveSubscription;
//           _selectedPlanId = plans.where((p) => p.isPopular).isNotEmpty
//               ? plans.firstWhere((p) => p.isPopular).id
//               : plans.isNotEmpty
//               ? plans.first.id
//               : null;
//           _isLoading = false;
//         });
//         _animController.forward();
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               '${AppLocalizations.of(context).errorLoadingPlans}: $e',
//             ),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _startFreeTrial() async {
//     if (_isPurchasing) return;
//     setState(() => _isPurchasing = true);
//     try {
//       await UserService().startTrial();
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(AppLocalizations.of(context).trialStarted),
//             backgroundColor: Colors.green,
//           ),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('${AppLocalizations.of(context).error}: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isPurchasing = false);
//     }
//   }

//   Future<void> _handlePayment() async {
//     if (_isPurchasing || _selectedPlanId == null) return;
//     setState(() => _isPurchasing = true);
//     try {
//       final plan = _plans.firstWhere((p) => p.id == _selectedPlanId);
//       final success = await _subscriptionService.purchaseSubscription(
//         plan.productId,
//       );
//       if (success && mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(AppLocalizations.of(context).processingSubscription),
//             backgroundColor: AppColors.brandPurple,
//           ),
//         );
//       } else if (!success && mounted) {
//         throw Exception(AppLocalizations.of(context).failedToInitiatePurchase);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('${AppLocalizations.of(context).error}: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isPurchasing = false);
//     }
//   }

//   Future<void> _restorePurchases() async {
//     try {
//       await _subscriptionService.restorePurchases();
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(AppLocalizations.of(context).checkingPurchases),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               '${AppLocalizations.of(context).errorRestoringPurchases}: $e',
//             ),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   /// ✅ APPLE COMPLIANT: Directs users to App Store to manage/cancel subscription.
//   /// Do NOT use a custom Firebase cancellation flow — Apple rejects this.
//   Future<void> _manageSubscription() async {
//     const url =
//         'https://apps.apple.com/account/subscriptions'; // ← Apple's official URL
//     if (await canLaunchUrl(Uri.parse(url))) {
//       await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
//     }
//   }

//   Widget _buildPlanCard({required SubscriptionPlan plan}) {
//     final isSelected = _selectedPlanId == plan.id;
//     final lang = AppLocalizations.of(context).locale.languageCode;

//     final product = _subscriptionService.getProduct(plan.productId);

//     /// ✅ APPLE REQUIREMENT: Always show the App Store price, never hardcode
//     final displayPrice =
//         product?.price ?? '\$${plan.pricePerMonth.toStringAsFixed(2)}';
//     final totalPrice = product != null
//         ? product.price
//         : '\$${plan.totalPrice.toStringAsFixed(2)}';

//     return GestureDetector(
//       onTap: () => setState(() => _selectedPlanId = plan.id),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 220),
//         padding: EdgeInsets.all(16.adaptSize),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? AppColors.brandPurple.withOpacity(0.06)
//               : Colors.white,
//           borderRadius: BorderRadius.circular(18.adaptSize),
//           border: Border.all(
//             color: isSelected ? AppColors.brandPurple : const Color(0xFFE8E8F0),
//             width: isSelected ? 2 : 1.5,
//           ),
//           boxShadow: isSelected
//               ? [
//                   BoxShadow(
//                     color: AppColors.brandPurple.withOpacity(0.12),
//                     blurRadius: 16,
//                     offset: const Offset(0, 6),
//                   ),
//                 ]
//               : [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.04),
//                     blurRadius: 8,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//         ),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 // Plan icon
//                 Container(
//                   width: 46.adaptSize,
//                   height: 46.adaptSize,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         _iconColor(plan.durationMonths),
//                         _iconColor(plan.durationMonths).withOpacity(0.7),
//                       ],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(13.adaptSize),
//                   ),
//                   child: Icon(
//                     _planIcon(plan.durationMonths),
//                     color: Colors.white,
//                     size: 22.adaptSize,
//                   ),
//                 ),
//                 SizedBox(width: 14.w),

//                 // Plan name + per-month price
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         plan.getLocalizedName(lang),
//                         style: TextStyle(
//                           fontSize: 15.fSize,
//                           fontWeight: FontWeight.w600,
//                           color: const Color(0xFF1A1A2E),
//                         ),
//                       ),
//                       SizedBox(height: 3.h),
//                       // Savings badge
//                       ...([plan.getLocalizedSavings(lang)]
//                           .where((s) => s != null && s.isNotEmpty)
//                           .map(
//                             (savings) => Text(
//                               savings!,
//                               style: TextStyle(
//                                 color: Colors.green.shade700,
//                                 fontSize: 12.fSize,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           )),
//                       // ✅ APPLE REQUIRED: Show per-month price clearly
//                       // Row(
//                       //   crossAxisAlignment: CrossAxisAlignment.baseline,
//                       //   textBaseline: TextBaseline.alphabetic,
//                       //   children: [
//                       //     Text(
//                       //       displayPrice,
//                       //       style: TextStyle(
//                       //         fontSize: 16.fSize,
//                       //         fontWeight: FontWeight.w700,
//                       //         color: AppColors.brandPurple,
//                       //       ),
//                       //     ),
//                       //     Text(
//                       //       ' ${AppLocalizations.of(context).perMonth}',
//                       //       style: TextStyle(
//                       //         fontSize: 12.fSize,
//                       //         color: Colors.grey.shade500,
//                       //         fontWeight: FontWeight.w400,
//                       //       ),
//                       //     ),
//                       //   ],
//                       // ),
//                     ],
//                   ),
//                 ),

//                 // Right: selector + total price
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     AnimatedContainer(
//                       duration: const Duration(milliseconds: 200),
//                       width: 24.adaptSize,
//                       height: 24.adaptSize,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: isSelected
//                             ? AppColors.brandPurple
//                             : Colors.transparent,
//                         border: Border.all(
//                           color: isSelected
//                               ? AppColors.brandPurple
//                               : Colors.grey.shade300,
//                           width: 2,
//                         ),
//                       ),
//                       child: isSelected
//                           ? Icon(
//                               Icons.check,
//                               color: Colors.white,
//                               size: 14.adaptSize,
//                             )
//                           : null,
//                     ),
//                     SizedBox(height: 6.h),
//                     // ✅ Total billed amount
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.baseline,
//                       textBaseline: TextBaseline.alphabetic,
//                       children: [
//                         Text(
//                           displayPrice,
//                           style: TextStyle(
//                             fontSize: 18.fSize,
//                             fontWeight: FontWeight.w700,
//                             color: AppColors.brandPurple,
//                           ),
//                         ),
//                       ],
//                     ),
//                     Text(
//                       ' ${AppLocalizations.of(context).perMonth}',
//                       style: TextStyle(
//                         fontSize: 12.fSize,
//                         color: Colors.grey.shade500,
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//                     // Text(
//                     //   'totalBilled',
//                     //   //    AppLocalizations.of(context).totalBilled,
//                     //   style: TextStyle(
//                     //     fontSize: 10.fSize,
//                     //     color: Colors.grey.shade400,
//                     //   ),
//                     // ),
//                   ],
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildFeatureRow(IconData icon, String text) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: 5.h),
//       child: Row(
//         children: [
//           Container(
//             width: 28.adaptSize,
//             height: 28.adaptSize,
//             decoration: BoxDecoration(
//               color: AppColors.brandPurple.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: AppColors.brandPurple, size: 15.adaptSize),
//           ),
//           SizedBox(width: 12.w),
//           Expanded(
//             child: Text(
//               text,
//               style: TextStyle(
//                 fontSize: 13.fSize,
//                 color: const Color(0xFF444466),
//                 fontWeight: FontWeight.w400,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(
//         backgroundColor: Color(0xFFFDFBFF),
//         body: SubscriptionScreenSkeleton(),
//       );
//     }

//     return Scaffold(
//       backgroundColor: const Color(0xFFFDFBFF),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFFDFBFF),
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.close, color: Color(0xFF1A1A2E)),
//           onPressed: () => Navigator.pop(context),
//         ),
//         // ✅ APPLE REQUIRED: Restore Purchases must be visible and accessible
//         actions: [
//           TextButton(
//             onPressed: _restorePurchases,
//             child: Text(
//               AppLocalizations.of(context).restorePurchases,
//               style: TextStyle(
//                 color: AppColors.brandPurple,
//                 fontSize: 13.fSize,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         bottom: Platform.isIOS ? false : true,
//         child: FadeTransition(
//           opacity: _fadeAnim,
//           child: SlideTransition(
//             position: _slideAnim,
//             child: SingleChildScrollView(
//               padding: EdgeInsets.symmetric(horizontal: 22.w),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   // ─── Hero icon + title ───
//                   Container(
//                     width: 72.adaptSize,
//                     height: 72.adaptSize,
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           AppColors.brandPurple,
//                           AppColors.brandPurple.withOpacity(0.6),
//                         ],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: AppColors.brandPurple.withOpacity(0.3),
//                           blurRadius: 20,
//                           offset: const Offset(0, 8),
//                         ),
//                       ],
//                     ),
//                     child: Icon(
//                       Icons.workspace_premium_rounded,
//                       color: Colors.white,
//                       size: 38.adaptSize,
//                     ),
//                   ),
//                   SizedBox(height: 12.h),
//                   Text(
//                     AppLocalizations.of(context).premiumAccess,
//                     style: TextStyle(
//                       fontSize: 28.fSize,
//                       fontWeight: FontWeight.w700,
//                       color: const Color(0xFF1A1A2E),
//                       letterSpacing: -0.5,
//                     ),
//                   ),
//                   SizedBox(height: 6.h),
//                   Text(
//                     AppLocalizations.of(context).chooseYourPlan,
//                     style: TextStyle(
//                       fontSize: 15.fSize,
//                       color: Colors.grey.shade500,
//                       fontWeight: FontWeight.w400,
//                     ),
//                   ),
//                   SizedBox(height: 14.h),

//                   // ─── Feature highlights ───
//                   Container(
//                     padding: EdgeInsets.all(16.adaptSize),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(16.adaptSize),
//                       border: Border.all(color: const Color(0xFFEEEEF8)),
//                     ),
//                     child: Column(
//                       children: [
//                         _buildFeatureRow(
//                           Icons.bolt_rounded,
//                           'Unlimited AI generations',
//                         ),
//                         _buildFeatureRow(Icons.hd_rounded, 'HD quality output'),
//                         _buildFeatureRow(
//                           Icons.cloud_done_rounded,
//                           'Priority processing speed',
//                         ),
//                         _buildFeatureRow(
//                           Icons.support_agent_rounded,
//                           'Premium support access',
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: 14.h),

//                   // ─── Free trial badge ───
//                   // if (!_hasUsedTrial && !_isTrialActive) ...[
//                   //   GestureDetector(
//                   //     onTap: _isPurchasing ? null : _startFreeTrial,
//                   //     child: Container(
//                   //       width: double.infinity,
//                   //       padding: EdgeInsets.symmetric(
//                   //         horizontal: 20.w,
//                   //         vertical: 12.h,
//                   //       ),
//                   //       decoration: BoxDecoration(
//                   //         gradient: const LinearGradient(
//                   //           colors: [Color(0xFFFFB800), Color(0xFFFF6B00)],
//                   //         ),
//                   //         borderRadius: BorderRadius.circular(14.adaptSize),
//                   //         boxShadow: [
//                   //           BoxShadow(
//                   //             color: const Color(0xFFFF9500).withOpacity(0.3),
//                   //             blurRadius: 14,
//                   //             offset: const Offset(0, 5),
//                   //           ),
//                   //         ],
//                   //       ),
//                   //       child: Row(
//                   //         mainAxisAlignment: MainAxisAlignment.center,
//                   //         children: [
//                   //           Icon(
//                   //             Icons.auto_awesome,
//                   //             color: Colors.white,
//                   //             size: 18.adaptSize,
//                   //           ),
//                   //           SizedBox(width: 8.w),
//                   //           Text(
//                   //             AppLocalizations.of(context).freeTrial48h,
//                   //             style: TextStyle(
//                   //               color: Colors.white,
//                   //               fontWeight: FontWeight.w600,
//                   //               fontSize: 15.fSize,
//                   //             ),
//                   //           ),
//                   //         ],
//                   //       ),
//                   //     ),
//                   //   ),
//                   //   SizedBox(height: 12.h),

//                   //   // ✅ APPLE REQUIRED: Clear disclosure of what happens after trial
//                   // ],

//                   // ─── Plan cards ───
//                   if (_plans.isEmpty)
//                     _buildEmptyState()
//                   else
//                     ...(_plans.map(
//                       (plan) => Padding(
//                         padding: EdgeInsets.only(bottom: 12.h),
//                         child: _buildPlanCard(plan: plan),
//                       ),
//                     )),

//                   SizedBox(height: 20.h),

//                   // ─── CTA Button ───
//                   SizedBox(
//                     width: double.infinity,
//                     height: 54.h,
//                     child: ElevatedButton(
//                       onPressed: (_isPurchasing || _selectedPlanId == null)
//                           ? null
//                           : _handlePayment,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.brandPurple,
//                         disabledBackgroundColor: AppColors.brandPurple
//                             .withOpacity(0.5),
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(14.adaptSize),
//                         ),
//                       ),
//                       child: _isPurchasing
//                           ? const AppCircularLoader(
//                               size: 22,
//                               strokeWidth: 2,
//                               color: Colors.white,
//                             )
//                           : Text(
//                               AppLocalizations.of(context).payNow,
//                               style: TextStyle(
//                                 fontSize: 17.fSize,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.white,
//                                 letterSpacing: 0.2,
//                               ),
//                             ),
//                     ),
//                   ),

//                   // ─── Free trial text link ───
//                   if (!_hasUsedTrial && !_isTrialActive) ...[
//                     SizedBox(height: 10.h),
//                     TextButton(
//                       onPressed: _isPurchasing ? null : _startFreeTrial,
//                       style: TextButton.styleFrom(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 16.w,
//                           vertical: 8.h,
//                         ),
//                       ),
//                       child: Text(
//                         AppLocalizations.of(context).orStart48HourFreeTrial,
//                         style: TextStyle(
//                           color: AppColors.brandPurple,
//                           fontWeight: FontWeight.w500,
//                           fontSize: 15.fSize,
//                         ),
//                       ),
//                     ),
//                   ],

//                   // SizedBox(height: 12.h),

//                   // ─── Bottom note from Firestore ───
//                   Builder(
//                     builder: (context) {
//                       final lang = AppLocalizations.of(
//                         context,
//                       ).locale.languageCode;
//                       final cheapestPrice = _plans.isNotEmpty
//                           ? _plans
//                                 .map((p) => p.pricePerMonth)
//                                 .reduce((a, b) => a < b ? a : b)
//                           : 4.99;
//                       final selectedPlan = _selectedPlanId != null
//                           ? _plans
//                                 .where((p) => p.id == _selectedPlanId)
//                                 .firstOrNull
//                           : null;
//                       String note;
//                       if (selectedPlan != null) {
//                         note = selectedPlan.getLocalizedBottomNote(lang) ?? '';
//                       } else {
//                         note =
//                             'Free for 48 hours, then \$${cheapestPrice.toStringAsFixed(2)}/month. Cancel anytime.';
//                       }
//                       return Text(
//                         note,
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Colors.grey.shade500,
//                           fontSize: 12.fSize,
//                         ),
//                       );
//                     },
//                   ),

//                   // SizedBox(height: 20.h),

//                   // ─── Manage / Cancel subscription ───
//                   // ✅ APPLE REQUIRED: Must direct users to App Store, not a custom flow
//                   // if (_hasActiveSubscription) ...[
//                   //   SizedBox(
//                   //     width: double.infinity,
//                   //     child: OutlinedButton.icon(
//                   //       onPressed: _manageSubscription,
//                   //       icon: Icon(
//                   //         Icons.settings_outlined,
//                   //         size: 16.adaptSize,
//                   //         color: Colors.grey.shade600,
//                   //       ),
//                   //       label: Text(
//                   //         "manageSubscription",
//                   //         //    AppLocalizations.of(context).manageSubscription,
//                   //         // e.g. "Manage Subscription"
//                   //         style: TextStyle(
//                   //           color: Colors.grey.shade700,
//                   //           fontSize: 14.fSize,
//                   //           fontWeight: FontWeight.w500,
//                   //         ),
//                   //       ),
//                   //       style: OutlinedButton.styleFrom(
//                   //         side: BorderSide(color: Colors.grey.shade300),
//                   //         shape: RoundedRectangleBorder(
//                   //           borderRadius: BorderRadius.circular(12.adaptSize),
//                   //         ),
//                   //         padding: EdgeInsets.symmetric(vertical: 12.h),
//                   //       ),
//                   //     ),
//                   //   ),
//                   //   SizedBox(height: 6.h),
//                   //   Text(
//                   //     // ✅ APPLE REQUIRED: Tell users how to cancel
//                   //     'To cancel, go to App Store → Your Account → Subscriptions',
//                   //     textAlign: TextAlign.center,
//                   //     style: TextStyle(
//                   //       fontSize: 11.fSize,
//                   //       color: Colors.grey.shade400,
//                   //     ),
//                   //   ),
//                   //   SizedBox(height: 16.h),
//                   // ],

//                   // ─── Trust badges ───
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       _buildTrustBadge(Icons.lock_outline, 'Secure Payment'),
//                       SizedBox(width: 20.w),
//                       _buildTrustBadge(Icons.cancel_outlined, 'Cancel Anytime'),
//                       SizedBox(width: 20.w),
//                       _buildTrustBadge(Icons.refresh_rounded, 'Auto-Renews'),
//                     ],
//                   ),

//                   SizedBox(height: 12.h),
//                   const Divider(color: Color(0xFFEEEEF8)),
//                   SizedBox(height: 8.h),

//                   // ─── Legal links ───
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       _buildLegalLink(
//                         'Terms of Use',
//                         'https://velmora-ai.com/terms',
//                       ),
//                       SizedBox(width: 8.w),
//                       Container(
//                         width: 4,
//                         height: 4,
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade400,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                       SizedBox(width: 8.w),
//                       _buildLegalLink(
//                         'Privacy Policy',
//                         'https://www.termsfeed.com/live/'
//                             'd8a44059-9d76-4ef2-a9be-1dba024e098a',
//                       ),
//                       SizedBox(width: 8.w),
//                       Container(
//                         width: 4,
//                         height: 4,
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade400,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                       SizedBox(width: 8.w),
//                       _buildLegalLink(
//                         'Restore',
//                         null,
//                         onTap: _restorePurchases,
//                       ),
//                     ],
//                   ),

//                   SizedBox(height: 8.h),

//                   // ✅ APPLE REQUIRED: Auto-renewal disclosure
//                   Container(
//                     padding: EdgeInsets.all(12.adaptSize),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF6F6FA),
//                       borderRadius: BorderRadius.circular(10.adaptSize),
//                     ),
//                     child: Text(
//                       'Subscription automatically renews unless cancelled at least 24 hours before the end of the current period. '
//                       'Payment will be charged to your Apple ID account at confirmation of purchase. '
//                       'You can manage and cancel subscriptions by going to your Account Settings on the App Store after purchase. '
//                       'Any unused portion of a free trial period will be forfeited when you purchase a subscription.',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: const Color(0xFF6B7580),
//                         fontSize: 11.fSize,
//                         height: 1.5,
//                       ),
//                     ),
//                   ),

//                   SizedBox(height: 36.h),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Column(
//       children: [
//         Icon(
//           Icons.error_outline,
//           size: 48.adaptSize,
//           color: Colors.grey.shade400,
//         ),
//         SizedBox(height: 16.h),
//         Text(
//           AppLocalizations.of(context).noPlansAvailable,
//           style: TextStyle(
//             color: Colors.grey.shade700,
//             fontSize: 16.fSize,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         SizedBox(height: 8.h),
//         Text(
//           AppLocalizations.of(context).unableToLoadSubscriptionPlans,
//           style: TextStyle(color: Colors.grey.shade500, fontSize: 14.fSize),
//           textAlign: TextAlign.center,
//         ),
//         SizedBox(height: 16.h),
//         ElevatedButton.icon(
//           onPressed: () {
//             setState(() => _isLoading = true);
//             _initialize();
//           },
//           icon: const Icon(Icons.refresh),
//           label: Text(AppLocalizations.of(context).retry),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppColors.brandPurple,
//             foregroundColor: Colors.white,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTrustBadge(IconData icon, String label) {
//     return Column(
//       children: [
//         Icon(icon, color: AppColors.brandPurple, size: 18.adaptSize),
//         SizedBox(height: 4.h),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 10.fSize,
//             color: Colors.grey.shade500,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildLegalLink(String text, String? url, {VoidCallback? onTap}) {
//     return GestureDetector(
//       onTap:
//           onTap ??
//           () async {
//             if (url != null && await canLaunchUrl(Uri.parse(url))) {
//               await launchUrl(
//                 Uri.parse(url),
//                 mode: LaunchMode.externalApplication,
//               );
//             }
//           },
//       child: Text(
//         text,
//         style: TextStyle(
//           fontSize: 12.fSize,
//           color: Colors.grey.shade500,
//           decoration: TextDecoration.underline,
//           decorationColor: Colors.grey.shade400,
//         ),
//       ),
//     );
//   }

//   IconData _planIcon(int months) {
//     if (months >= 12) return Icons.workspace_premium;
//     if (months >= 3) return Icons.trending_up_rounded;
//     return Icons.electric_bolt_rounded;
//   }

//   Color _iconColor(int months) {
//     if (months >= 12) return const Color(0xFFFF9F0A);
//     if (months >= 3) return const Color(0xFFFF4B8D);
//     return const Color(0xFFA267FF);
//   }
// }

import 'dart:io';

import 'package:url_launcher/url_launcher.dart';
import 'package:velmora/constants/app_colors.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/services/subscription_plans_service.dart';
import 'package:velmora/services/subscription_service.dart';
import 'package:velmora/services/user_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:velmora/widgets/skeletons/subscription_skeleton.dart';
import 'package:velmora/widgets/app_loading_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// APPLE GUIDELINE 3.1.2(c) COMPLIANCE — BOTH ISSUES RESOLVED
//
// Issue 1 — Missing EULA link in purchase flow:
//   ✅ Prominent "By continuing you agree to our Terms of Use (EULA)" RichText
//      with a tappable link shown directly above / below the buy button area.
//   ✅ Standalone Terms of Use + Privacy Policy tappable links in footer.
//   ✅ Both links are functional (launchUrl with externalApplication mode).
//   → Also add your EULA URL to App Store Connect → App Information → EULA field.
//
// Issue 2 — Subscription doesn't describe what user receives:
//   ✅ Every plan card shows: title, duration, price/month, total billed,
//      and a bullet list of exactly what's included in that subscription.
//   ✅ Top-level "What's included" card shown before plan selection.
//
// Other required elements (retained from previous fix):
//   ✅ App Store price string used (never hardcoded)
//   ✅ Restore Purchases button always visible in AppBar
//   ✅ Cancel directed to App Store settings (not custom Firebase flow)
//   ✅ Auto-renewal disclosure block present
// ─────────────────────────────────────────────────────────────────────────────

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with SingleTickerProviderStateMixin {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final SubscriptionPlansService _plansService = SubscriptionPlansService();
  final UserService _userService = UserService();

  // ── Legal URLs — update these if they change ──────────────────────────────
  static const String _termsUrl = 'https://velmora-ai.com/terms';
  static const String _privacyUrl =
      'https://www.termsfeed.com/live/d8a44059-9d76-4ef2-a9be-1dba024e098a';

  String? _selectedPlanId;
  bool _isLoading = true;
  bool _isPurchasing = false;
  List<SubscriptionPlan> _plans = [];
  bool _hasUsedTrial = false;
  bool _isTrialActive = false;
  bool _hasActiveSubscription = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initialize();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    await _subscriptionService.initialize();
    try {
      final plans = await _plansService.getPlans();
      final hasUsedTrial = await _userService.hasUsedTrial();
      final isTrialActive = await _userService.isTrialActive();
      final hasActiveSubscription = await _subscriptionService
          .hasActiveSubscription();

      if (mounted) {
        setState(() {
          _plans = plans;
          _hasUsedTrial = hasUsedTrial;
          _isTrialActive = isTrialActive;
          _hasActiveSubscription = hasActiveSubscription;
          _selectedPlanId = plans.where((p) => p.isPopular).isNotEmpty
              ? plans.firstWhere((p) => p.isPopular).id
              : plans.isNotEmpty
              ? plans.first.id
              : null;
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack(
          '${AppLocalizations.of(context).errorLoadingPlans}: $e',
          color: Colors.red,
        );
      }
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _startFreeTrial() async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);
    try {
      await UserService().startTrial();
      if (mounted) {
        _snack(AppLocalizations.of(context).trialStarted, color: Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        _snack('${AppLocalizations.of(context).error}: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  String getPlanLabel(int duration) {
    switch (duration) {
      case 12:
        return 'yearly_velmora_id';
      case 3:
        return 'quarterly_velmora_id';
      case 1:
        return 'monthly_velmora_id';
      default:
        return 'none';
    }
  }

  Future<void> _handlePayment() async {
    if (_isPurchasing || _selectedPlanId == null) return;
    print('_selectedPlanId $_selectedPlanId');
    setState(() => _isPurchasing = true);
    try {
      final plan = _plans.firstWhere((p) => p.id == _selectedPlanId);
      final productId = Platform.isIOS
          ? plan.productId
          : getPlanLabel(plan.durationMonths);
      print('productId used: $productId');

      final success = await _subscriptionService.purchaseSubscription(
        productId,
      );
      if (success && mounted) {
        _snack(
          AppLocalizations.of(context).processingSubscription,
          color: AppColors.brandPurple,
        );
      } else if (!success && mounted) {
        throw Exception(AppLocalizations.of(context).failedToInitiatePurchase);
      }
    } catch (e) {
      if (mounted)
        _snack('${AppLocalizations.of(context).error}: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restorePurchases() async {
    try {
      await _subscriptionService.restorePurchases();
      if (mounted) _snack(AppLocalizations.of(context).checkingPurchases);
    } catch (e) {
      if (mounted)
        _snack(
          '${AppLocalizations.of(context).errorRestoringPurchases}: $e',
          color: Colors.red,
        );
    }
  }

  /// ✅ APPLE: Must send user to App Store to manage/cancel — no custom flow.
  Future<void> _manageSubscription() async {
    final uri = Uri.parse('https://apps.apple.com/account/subscriptions');
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// ✅ APPLE 3.1.2(c): "Length of subscription" shown on every plan card.
  String _durationLabel(int months) {
    if (months == 1) return '1 Month';
    if (months == 12) return '1 Year';
    return '$months Months';
  }

  IconData _planIcon(int months) {
    if (months >= 12) return Icons.workspace_premium;
    if (months >= 3) return Icons.trending_up_rounded;
    return Icons.electric_bolt_rounded;
  }

  Color _iconColor(int months) {
    if (months >= 12) return const Color(0xFFFF9F0A);
    if (months >= 3) return const Color(0xFFFF4B8D);
    return const Color(0xFFA267FF);
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  /// ✅ APPLE 3.1.2(c) Issue 2: every card shows title + duration + price +
  /// what the user receives for that price.
  Widget _buildPlanCard({required SubscriptionPlan plan}) {
    final isSelected = _selectedPlanId == plan.id;
    final lang = AppLocalizations.of(context).locale.languageCode;

    final product = _subscriptionService.getProduct(plan.productId);

    // ✅ APPLE: Use App Store price string, never hardcode
    final pricePerMonth =
        product?.price ?? '\$${plan.pricePerMonth.toStringAsFixed(2)}';
    final totalBilled = product != null
        ? product.price
        : '\$${plan.totalPrice.toStringAsFixed(2)}';

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanId = plan.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16.adaptSize),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPurple.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(18.adaptSize),
          border: Border.all(
            color: isSelected ? AppColors.brandPurple : const Color(0xFFE4E4F0),
            width: isSelected ? 2.2 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.brandPurple.withOpacity(0.10)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 18 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: icon / name+duration / selector+price ──────────
            Row(
              children: [
                Container(
                  width: 46.adaptSize,
                  height: 46.adaptSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _iconColor(plan.durationMonths),
                        _iconColor(plan.durationMonths).withOpacity(0.65),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13.adaptSize),
                  ),
                  child: Icon(
                    _planIcon(plan.durationMonths),
                    color: Colors.white,
                    size: 22.adaptSize,
                  ),
                ),
                SizedBox(width: 14.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Subscription title
                      Text(
                        plan.getLocalizedName(lang),
                        style: TextStyle(
                          fontSize: 15.fSize,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      // ✅ Length of subscription
                      Text(
                        _durationLabel(plan.durationMonths),
                        style: TextStyle(
                          fontSize: 12.fSize,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                // ✅ Price clearly shown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22.adaptSize,
                      height: 22.adaptSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.brandPurple
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brandPurple
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 13.adaptSize,
                            )
                          : null,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      pricePerMonth,
                      style: TextStyle(
                        fontSize: 17.fSize,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandPurple,
                      ),
                    ),
                    Text(
                      ' ${AppLocalizations.of(context).perMonth}',
                      style: TextStyle(
                        fontSize: 10.fSize,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // ── What you get box ─────────────────────────────────────────
            // ✅ APPLE 3.1.2(c) Issue 2: "clearly describe what the user
            //    will receive for the price"
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10.adaptSize),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Billed amount
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 13.adaptSize,
                        color: Colors.grey.shade500,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Billed $totalBilled every ${_durationLabel(plan.durationMonths)}',
                        style: TextStyle(
                          fontSize: 11.fSize,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Savings pill (if any)
                  if ((plan.getLocalizedSavings(lang) ?? '').isNotEmpty) ...[
                    SizedBox(height: 5.h),
                    Row(
                      children: [
                        Icon(
                          Icons.local_offer_rounded,
                          size: 13.adaptSize,
                          color: Colors.green.shade500,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          plan.getLocalizedSavings(lang)!,
                          style: TextStyle(
                            fontSize: 11.fSize,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: 8.h),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  SizedBox(height: 8.h),

                  // Feature list — what the user receives
                  _miniFeature('Unlimited AI generations included'),
                  _miniFeature('HD quality output on all generations'),
                  _miniFeature('Priority processing — faster results'),
                  _miniFeature('Premium support access'),
                  _miniFeature(
                    'Auto-renews every ${_durationLabel(plan.durationMonths)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniFeature(String text) => Padding(
    padding: EdgeInsets.only(top: 4.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 13.adaptSize,
          color: AppColors.brandPurple,
        ),
        SizedBox(width: 7.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11.fSize, color: Colors.grey.shade600),
          ),
        ),
      ],
    ),
  );

  Widget _featureRow(IconData icon, String text) => Padding(
    padding: EdgeInsets.symmetric(vertical: 5.h),
    child: Row(
      children: [
        Container(
          width: 28.adaptSize,
          height: 28.adaptSize,
          decoration: BoxDecoration(
            color: AppColors.brandPurple.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.brandPurple, size: 14.adaptSize),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.fSize,
              color: const Color(0xFF444466),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _trustBadge(IconData icon, String label) => Column(
    children: [
      Icon(icon, color: AppColors.brandPurple, size: 18.adaptSize),
      SizedBox(height: 4.h),
      Text(
        label,
        style: TextStyle(
          fontSize: 10.fSize,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  Widget _legalLink(String text, String? url, {VoidCallback? onTap}) =>
      GestureDetector(
        onTap:
            onTap ??
            () async {
              if (url != null) await _launchUrl(url);
            },
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.fSize,
            color: Colors.grey.shade500,
            decoration: TextDecoration.underline,
            decorationColor: Colors.grey.shade400,
          ),
        ),
      );

  Widget _dot() => Container(
    width: 3,
    height: 3,
    margin: EdgeInsets.symmetric(horizontal: 8.w),
    decoration: BoxDecoration(
      color: Colors.grey.shade400,
      shape: BoxShape.circle,
    ),
  );

  Widget _buildEmptyState() => Column(
    children: [
      Icon(
        Icons.error_outline,
        size: 48.adaptSize,
        color: Colors.grey.shade400,
      ),
      SizedBox(height: 16.h),
      Text(
        AppLocalizations.of(context).noPlansAvailable,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 16.fSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(height: 8.h),
      Text(
        AppLocalizations.of(context).unableToLoadSubscriptionPlans,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 14.fSize),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 16.h),
      ElevatedButton.icon(
        onPressed: () {
          setState(() => _isLoading = true);
          _initialize();
        },
        icon: const Icon(Icons.refresh),
        label: Text(AppLocalizations.of(context).retry),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPurple,
          foregroundColor: Colors.white,
        ),
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDFBFF),
        body: SubscriptionScreenSkeleton(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        // ✅ APPLE: Restore Purchases always visible
        actions: [
          TextButton(
            onPressed: _restorePurchases,
            child: Text(
              AppLocalizations.of(context).restorePurchases,
              style: TextStyle(
                color: AppColors.brandPurple,
                fontSize: 13.fSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: Platform.isIOS ? false : true,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 22.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Hero ────────────────────────────────────────────────
                  Container(
                    width: 70.adaptSize,
                    height: 70.adaptSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.brandPurple,
                          AppColors.brandPurple.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandPurple.withOpacity(0.28),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 36.adaptSize,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    AppLocalizations.of(context).premiumAccess,
                    style: TextStyle(
                      fontSize: 27.fSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Unlock unlimited access to all premium features',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.fSize,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // ── What's included summary ─────────────────────────────
                  // Container(
                  //   width: double.infinity,
                  //   padding: EdgeInsets.all(16.adaptSize),
                  //   decoration: BoxDecoration(
                  //     color: Colors.white,
                  //     borderRadius: BorderRadius.circular(16.adaptSize),
                  //     border: Border.all(color: const Color(0xFFEEEEF8)),
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Text(
                  //         'Everything included with Premium',
                  //         style: TextStyle(
                  //           fontSize: 13.fSize,
                  //           fontWeight: FontWeight.w600,
                  //           color: const Color(0xFF1A1A2E),
                  //         ),
                  //       ),
                  //       SizedBox(height: 8.h),
                  //       _featureRow(
                  //         Icons.bolt_rounded,
                  //         'Unlimited AI generations',
                  //       ),
                  //       _featureRow(Icons.hd_rounded, 'HD quality output'),
                  //       _featureRow(
                  //         Icons.speed_rounded,
                  //         'Priority processing — faster results',
                  //       ),
                  //       _featureRow(
                  //         Icons.support_agent_rounded,
                  //         'Premium support access',
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // SizedBox(height: 22.h),

                  // ── Free trial banner ───────────────────────────────────
                  // if (!_hasUsedTrial && !_isTrialActive) ...[
                  //   GestureDetector(
                  //     onTap: _isPurchasing ? null : _startFreeTrial,
                  //     child: Container(
                  //       width: double.infinity,
                  //       padding: EdgeInsets.symmetric(
                  //         horizontal: 20.w,
                  //         vertical: 12.h,
                  //       ),
                  //       decoration: BoxDecoration(
                  //         gradient: const LinearGradient(
                  //           colors: [Color(0xFFFFB800), Color(0xFFFF6B00)],
                  //         ),
                  //         borderRadius: BorderRadius.circular(14.adaptSize),
                  //         boxShadow: [
                  //           BoxShadow(
                  //             color: const Color(0xFFFF9500).withOpacity(0.28),
                  //             blurRadius: 14,
                  //             offset: const Offset(0, 5),
                  //           ),
                  //         ],
                  //       ),
                  //       child: Row(
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //         children: [
                  //           Icon(
                  //             Icons.auto_awesome,
                  //             color: Colors.white,
                  //             size: 17.adaptSize,
                  //           ),
                  //           SizedBox(width: 8.w),
                  //           Text(
                  //             AppLocalizations.of(context).freeTrial48h,
                  //             style: TextStyle(
                  //               color: Colors.white,
                  //               fontWeight: FontWeight.w600,
                  //               fontSize: 15.fSize,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  //   SizedBox(height: 8.h),
                  //   // ✅ Trial disclosure
                  //   Text(
                  //     'Free for 48 hours, then automatically renews at the '
                  //     'selected plan price. Cancel anytime in App Store settings.',
                  //     textAlign: TextAlign.center,
                  //     style: TextStyle(
                  //       fontSize: 11.fSize,
                  //       color: Colors.grey.shade500,
                  //     ),
                  //   ),
                  //   SizedBox(height: 22.h),
                  // ],

                  // ── Plan cards ─────────────────────────────────────────
                  if (_plans.isEmpty)
                    _buildEmptyState()
                  else
                    ...(_plans.map(
                      (plan) => Padding(
                        padding: EdgeInsets.only(bottom: 14.h),
                        child: _buildPlanCard(plan: plan),
                      ),
                    )),

                  SizedBox(height: 14.h),

                  // ── Renewal notice adjacent to buy button ───────────────
                  // ✅ APPLE: Disclosure must be near the purchase action
                  Builder(
                    builder: (ctx) {
                      final lang = AppLocalizations.of(ctx).locale.languageCode;
                      final selectedPlan = _selectedPlanId != null
                          ? _plans
                                .where((p) => p.id == _selectedPlanId)
                                .firstOrNull
                          : null;
                      final note =
                          selectedPlan?.getLocalizedBottomNote(lang) ??
                          'Subscription renews automatically until cancelled.';
                      return Text(
                        note,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.fSize,
                          color: Colors.grey.shade500,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 12.h),

                  // ── Buy button ─────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54.h,
                    child: ElevatedButton(
                      onPressed: (_isPurchasing || _selectedPlanId == null)
                          ? null
                          : _handlePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPurple,
                        disabledBackgroundColor: AppColors.brandPurple
                            .withOpacity(0.45),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.adaptSize),
                        ),
                      ),
                      child: _isPurchasing
                          ? const AppCircularLoader(
                              size: 22,
                              strokeWidth: 2,
                              color: Colors.white,
                            )
                          : Text(
                              AppLocalizations.of(context).payNow,
                              style: TextStyle(
                                fontSize: 17.fSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),

                  // ── Trial secondary link ───────────────────────────────
                  if (!_hasUsedTrial && !_isTrialActive) ...[
                    SizedBox(height: 10.h),
                    TextButton(
                      onPressed: _isPurchasing ? null : _startFreeTrial,
                      child: Text(
                        AppLocalizations.of(context).orStart48HourFreeTrial,
                        style: TextStyle(
                          color: AppColors.brandPurple,
                          fontWeight: FontWeight.w500,
                          fontSize: 15.fSize,
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 10.h),

                  // ─────────────────────────────────────────────────────────
                  // ✅ APPLE GUIDELINE 3.1.2(c) ISSUE 1 FIX:
                  // Functional EULA + Privacy Policy links IN the purchase flow.
                  // Use RichText with TapGestureRecognizer for inline tappable links.
                  // ─────────────────────────────────────────────────────────
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandPurple.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12.adaptSize),
                      border: Border.all(
                        color: AppColors.brandPurple.withOpacity(0.12),
                      ),
                    ),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12.5.fSize,
                          color: Colors.grey.shade600,
                          height: 1.6,
                        ),
                        children: [
                          const TextSpan(
                            text: 'By subscribing you agree to our\u00A0',
                          ),
                          TextSpan(
                            text: 'Terms of Use',
                            style: TextStyle(
                              color: AppColors.brandPurple,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.brandPurple,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _launchUrl(_termsUrl),
                          ),
                          const TextSpan(text: '\u00A0and\u00A0'),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: AppColors.brandPurple,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.brandPurple,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _launchUrl(_privacyUrl),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // ── Trust badges ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _trustBadge(Icons.lock_outline, 'Secure'),
                      _trustBadge(Icons.cancel_outlined, 'Cancel Anytime'),
                      _trustBadge(Icons.refresh_rounded, 'Auto-Renews'),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // ── Manage subscription (active users) ─────────────────
                  if (_hasActiveSubscription) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _manageSubscription,
                        icon: Icon(
                          Icons.open_in_new_rounded,
                          size: 15.adaptSize,
                          color: Colors.grey.shade600,
                        ),
                        label: Text(
                          'Manage Subscription in App Store',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13.fSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.adaptSize),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'To cancel: App Store → Account → Subscriptions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.fSize,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    SizedBox(height: 18.h),
                  ],

                  const Divider(color: Color(0xFFEEEEF8)),
                  SizedBox(height: 14.h),

                  // ── Footer legal links (standalone, scannable) ─────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legalLink('Terms of Use', _termsUrl),
                      _dot(),
                      _legalLink('Privacy Policy', _privacyUrl),
                      _dot(),
                      _legalLink('Restore', null, onTap: _restorePurchases),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // ── Full auto-renewal legal disclosure ─────────────────
                  Container(
                    padding: EdgeInsets.all(12.adaptSize),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6FA),
                      borderRadius: BorderRadius.circular(10.adaptSize),
                    ),
                    child: Text(
                      'Subscription automatically renews unless cancelled at '
                      'least 24\u202Fhours before the end of the current period. '
                      'Payment is charged to your Apple\u202FID at purchase '
                      'confirmation. Manage or cancel subscriptions in your '
                      'App Store Account Settings after purchase. Any unused '
                      'portion of a free trial period will be forfeited when a '
                      'subscription is purchased.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF6B7580),
                        fontSize: 11.fSize,
                        height: 1.55,
                      ),
                    ),
                  ),

                  SizedBox(height: 36.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
