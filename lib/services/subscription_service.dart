import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velmora/main.dart';
import 'package:velmora/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/widgets/loading_widget.dart';

import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

//
/// Subscription Service for managing in-app purchases
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal() {
    // _dio = Dio(
    //   BaseOptions(
    //     baseUrl: 'https://api.velmora.com', // Replace with your actual liveUrl
    //     connectTimeout: const Duration(seconds: 10),
    //     receiveTimeout: const Duration(seconds: 10),
    //   ),
    // );
  }

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // late final Dio _dio;

  // Product IDs - These must match your App Store Connect and Google Play Console configuration
  static String monthlySubscriptionId = Platform.isIOS
      ? 'Monthly_velmora_id'
      : 'monthly_velmora_id';
  static String quarterlySubscriptionId = Platform.isIOS
      ? 'Quarterly_velmora_id'
      : 'quaterly_velmora_id';
  static String yearlySubscriptionId = Platform.isIOS
      ? 'Yearly_velmora_id'
      : "yearly_velmora_id";

  static final List<String> _productIds = [
    monthlySubscriptionId,
    quarterlySubscriptionId,
    yearlySubscriptionId,
  ];

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _isInitialized = false;

  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;

  /// Initialize the subscription service
  Future<void> initialize() async {
    print('_isInitialized $_isInitialized');
    if (_isInitialized) return;

    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      print('_isAvailable $_isAvailable');
      if (!_isAvailable) {
        if (kDebugMode) print('In-app purchase not available');
        return;
      }

      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          if (kDebugMode) print('Purchase stream error: $error');
        },
      );

      await loadProducts();
      await _checkLocalSubscriptionStatus();
      // / ✅ This handles both new device + existing device
      // await checkAndRestoreSubscription();
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _verifyFromGooglePlay();
      }

      _isInitialized = true;
      if (kDebugMode) print('Subscription service initialized');
    } catch (e) {
      if (kDebugMode) print('Error initializing subscription service: $e');
    }
  }

  Future<void> checkAndRestoreSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // ✅ Step 1 — Check Firebase first (fastest, works offline)
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        final isPremium = data?['isPremium'] ?? false;
        final expiryTimestamp = data?['subscriptionExpiryDate'] as Timestamp?;

        if (isPremium && expiryTimestamp != null) {
          final expiry = expiryTimestamp.toDate();

          if (DateTime.now().isBefore(expiry)) {
            // ✅ Still valid — save locally and return
            final subType = data?['subscriptionType'] ?? '';
            await _saveSubscriptionState(subType);
            if (kDebugMode) {
              print('✅ Subscription valid from Firebase. Expiry: $expiry');
            }
            return;
          } else {
            // ❌ Expired in Firebase — revoke and try restore
            if (kDebugMode) {
              print('⚠️ Firebase subscription expired. Trying restore...');
            }
            await _revokeSubscription(user.uid);
          }
        }
      }

      // ✅ Step 2 — Firebase has no valid sub, try restoring from Store
      // This triggers _onPurchaseUpdate → _verifyAndDeliverProduct
      // which recalculates expiry from purchase_date_ms and saves to Firebase
      if (kDebugMode) print('🔄 Restoring purchases from store...');
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      if (kDebugMode) print('Error in checkAndRestoreSubscription: $e');
    }
  }

  /// Load available products
  Future<void> loadProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(_productIds.toSet());
      print('response $response');
      if (response.error != null) {
        if (kDebugMode) print('Error loading products: ${response.error}');
        return;
      }
      _products = response.productDetails;
      print('_products ${_products.length}');
    } catch (e) {
      if (kDebugMode) print('Error loading products: $e');
    }
  }

  void showLoadingDialog() {
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false, // ❌ Prevent closing by tapping outside
      builder: (context) {
        return Container(
          margin: EdgeInsets.all(20.adaptSize),
          height: 50.h,
          width: 50.w,
          color: Colors.transparent, // keeps background transparent
          child: LoadingIndicatorWideget(),
        );
      },
    );
  }

  /// Purchase a subscription
  Future<bool> purchaseSubscription(String productId) async {
    try {
      showLoadingDialog();
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found'),
      );

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );
      _purchasePending = true;

      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      hideLoadingDialog();
      return success;
    } catch (e) {
      print('Error purchasing subscription: $e');
      _purchasePending = false;
      hideLoadingDialog();
      return false;
    }
  }

  void hideLoadingDialog() {
    // if (Navigator.canPop(context)) {
    //   Navigator.of(context).pop();
    // }navigatorKey.currentState
    final navState = navigatorKey.currentState;
    if (navState != null && navState.canPop()) {
      navState.pop();
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      if (kDebugMode) print('Error restoring purchases: $e');
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _purchasePending = true;
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await _verifyAndDeliverProduct(purchaseDetails);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }

        _purchasePending = false;
      }
    }
  }

  /// Verify and deliver the product
  Future<void> _verifyAndDeliverProduct(PurchaseDetails purchaseDetails) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      String purchaseToken = '';
      String platform = 'ios';
      DateTime? realExpiry; // ← holds verified expiry

      if (defaultTargetPlatform == TargetPlatform.android) {
        if (purchaseDetails is GooglePlayPurchaseDetails) {
          purchaseToken = purchaseDetails.billingClientPurchase.purchaseToken;
          platform = "android";

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('android_purchase_token', purchaseToken);

          // Android: use calculated expiry (until you add server-side verification)
          realExpiry = _calculateExpiryDate(purchaseDetails.productID);
        }
      } else {
        purchaseToken = purchaseDetails.verificationData.serverVerificationData;
        platform = "ios";

        final expiry = await _verifyIOSReceipt(purchaseToken);
        if (expiry == null) {
          await _revokeSubscription(user.uid);
          if (kDebugMode) print("❌ iOS receipt invalid");
          return;
        }
        if (expiry.isBefore(DateTime.now())) {
          await _revokeSubscription(user.uid);
          if (kDebugMode) print("❌ iOS subscription expired");
          return;
        }

        realExpiry = expiry; // ← real Apple expiry
        if (kDebugMode) print("✅ iOS receipt verified. Expiry: $expiry");
      }

      // Fallback (should never hit this)
      realExpiry ??= _calculateExpiryDate(purchaseDetails.productID);

      // ✅ Pass real expiry
      await _syncWithFirebase(
        user.uid,
        purchaseDetails,
        purchaseToken,
        platform,
        realExpiry,
      );
      await _saveSubscriptionState(purchaseDetails.productID);

      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('preferred_language') ?? 'en';
      final l10n = AppLocalizations(Locale(langCode));

      NotificationService().addInAppNotification(
        title: l10n.subscriptionActivated,
        body: l10n.subscriptionActivatedBody,
        type: 'subscription',
      );

      if (kDebugMode) {
        print('Premium subscription processed for user: ${user.uid}');
      }
    } catch (e) {
      if (kDebugMode) print('Error delivering product: $e');
    }
  }

  /// Verify existing subscriptions with Google Play
  Future<void> _verifyFromGooglePlay() async {
    try {
      log("Verifying existing subscriptions with Google Play...");

      final googlePlayPlatform = _inAppPurchase
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

      final response = await googlePlayPlatform.queryPastPurchases();

      if (response.error != null) {
        if (kDebugMode) {
          print('❌ Failed to query past purchases: ${response.error!.message}');
        }
        return;
      }

      if (response.pastPurchases.isEmpty) {
        log("No past purchases found.");
        final user = _auth.currentUser;
        if (user != null) await _revokeSubscription(user.uid);
        return;
      }

      // Find an active subscription among past purchases
      PurchaseDetails? activeSub;
      try {
        activeSub = response.pastPurchases.firstWhere(
          (purchase) =>
              purchase.status == PurchaseStatus.purchased &&
              _productIds.contains(purchase.productID),
        );
      } catch (_) {
        activeSub = null;
      }

      if (activeSub == null) {
        log("❌ No active subscription found in past purchases.");
        final user = _auth.currentUser;
        if (user != null) await _revokeSubscription(user.uid);
        return;
      }

      log("✅ Found active subscription: ${activeSub.productID}");

      // Complete pending purchases if needed
      if (activeSub.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(activeSub);
      }

      await _verifyAndDeliverProduct(activeSub);
    } catch (e) {
      if (kDebugMode) print('Error verifying from Google Play: $e');
    }
  }

  // Future<DateTime?> _verifyIOSReceipt(String receiptData) async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse(
  //         // 'https://sandbox.itunes.apple.com/verifyReceipt',
  //         kDebugMode
  //             ? 'https://sandbox.itunes.apple.com/verifyReceipt'
  //             : 'https://buy.itunes.apple.com/verifyReceipt',
  //       ),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({
  //         'receipt-data': receiptData,
  //         'password': '5fca1d839d9842abb31b930454ba817e',
  //         'exclude-old-transactions': true, // Recommended
  //       }),
  //     );

  //     if (response.statusCode != 200) return null;
  //     print('StatusCode: ${response.statusCode}');
  //     final data = jsonDecode(response.body);
  //     // log('data[status] ${data}');
  //     // log('response.body ${response.body}');
  //     if (data['status'] == 0) {
  //       final List<dynamic>? latestReceiptInfo = data['latest_receipt_info'];
  //       log('latestReceiptInfo ${latestReceiptInfo}');
  //       if (latestReceiptInfo != null && latestReceiptInfo.isNotEmpty) {
  //         final latest = latestReceiptInfo.last;
  //         final int expiresMs = int.tryParse(latest['expires_date_ms']!)!;
  //         log('expiresMs ====>> $expiresMs');
  //         final DateTime expiration = DateTime.fromMillisecondsSinceEpoch(
  //           expiresMs,
  //         );
  //         return expiration;
  //       }
  //     }

  //     return null;
  //   } catch (e) {
  //     if (kDebugMode) print("iOS verify error: $e");
  //     return null;
  //   }
  // }
  Future<DateTime?> _verifyIOSReceipt(String receiptData) async {
    try {
      final response = await http.post(
        Uri.parse(
          kDebugMode
              ? 'https://sandbox.itunes.apple.com/verifyReceipt'
              : 'https://buy.itunes.apple.com/verifyReceipt',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'receipt-data': receiptData,
          'password': '5fca1d839d9842abb31b930454ba817e',
          'exclude-old-transactions': true,
        }),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      log('Apple receipt status: ${data['status']}');

      if (data['status'] != 0) {
        if (kDebugMode) print("❌ Apple receipt status: ${data['status']}");
        return null;
      }

      // ✅ latest_receipt_info is sufficient — no need for in_app fallback
      final List<dynamic>? latestReceiptInfo = data['latest_receipt_info'];
      log('latestReceiptInfo count: ${latestReceiptInfo?.length}');

      if (latestReceiptInfo == null || latestReceiptInfo.isEmpty) {
        if (kDebugMode) print("❌ No receipt info found");
        return null;
      }

      // ✅ Find the most recent transaction matching YOUR product IDs
      Map<String, dynamic>? matchedTransaction;
      int latestPurchaseMs = 0;

      for (final transaction in latestReceiptInfo) {
        final productId = transaction['product_id'] as String?;
        final purchaseMsStr = transaction['purchase_date_ms'] as String?;

        log(
          'Checking transaction — product: $productId, purchase_date_ms: $purchaseMsStr',
        );

        if (productId == null || purchaseMsStr == null) continue;

        // ✅ Only match YOUR valid product IDs
        if (!_productIds.contains(productId)) {
          log('⚠️ Skipping unknown product: $productId');
          continue;
        }

        final purchaseMs = int.tryParse(purchaseMsStr) ?? 0;
        if (purchaseMs > latestPurchaseMs) {
          latestPurchaseMs = purchaseMs;
          matchedTransaction = Map<String, dynamic>.from(transaction);
        }
      }

      if (matchedTransaction == null) {
        if (kDebugMode) print("❌ No matching product ID found in receipt");
        return null;
      }

      final String productId = matchedTransaction['product_id'];
      final DateTime purchaseDate = DateTime.fromMillisecondsSinceEpoch(
        latestPurchaseMs,
      );

      log('✅ Matched product: $productId');
      log('✅ Purchase date: $purchaseDate');

      // ✅ Calculate expiry from purchase date + package duration
      final DateTime expiry = _calculateExpiryFromDate(productId, purchaseDate);
      log('✅ Calculated expiry: $expiry');

      return expiry;
    } catch (e) {
      if (kDebugMode) print("iOS verify error: $e");
      return null;
    }
  }

  /// Calculate expiry from actual purchase date (not DateTime.now())
  DateTime _calculateExpiryFromDate(String productId, DateTime purchaseDate) {
    if (productId == yearlySubscriptionId) {
      return purchaseDate.add(const Duration(days: 365));
    } else if (productId == quarterlySubscriptionId) {
      return purchaseDate.add(const Duration(days: 90));
    } else {
      return purchaseDate.add(const Duration(days: 30));
    }
  }
  // Future<bool> _sendReceiptToBackend({
  //   required String productId,
  //   required String receiptData,
  //   required String platform,
  // }) async {
  //   try {
  //     // In a real app, you'd get the Auth token from your LocalStorage/AuthService
  //     // For now we'll assume the backend is reachable
  //     final response = await _dio.post(
  //       '/subscribe',
  //       data: jsonEncode({
  //         "plan": productId,
  //         "subscription_id": receiptData,
  //         "device_type": platform,
  //         "is_premium": true,
  //       }),
  //     );
  //     return response.statusCode == 200 || response.statusCode == 201;
  //   } catch (e) {
  //     if (kDebugMode) print('Backend verification error: $e');
  //     // If backend fails, we might still want to give access if it's a dev mode
  //     // return kDebugMode;
  //     return true; // For now returning true to allow progress
  //   }
  // }

  Future<void> _syncWithFirebase(
    String uid,
    PurchaseDetails purchase,
    String token,
    String platform,
    DateTime expiryDate, // ← add real expiry param
  ) async {
    // final expiryDate = _calculateExpiryDate(purchase.productID);

    await _firestore.collection('users').doc(uid).update({
      'isPremium': true,
      'subscriptionStatus': 'premium',
      'subscriptionType': purchase.productID,
      'subscriptionExpiryDate': Timestamp.fromDate(expiryDate),
      'lastPurchaseId': purchase.purchaseID,
      'featuresAccess': {'games': true, 'kegel': true, 'chat': true},
      'receiptData': token,
      'platform': platform,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('subscription_receipts').add({
      'userId': uid,
      'productId': purchase.productID,
      'purchaseId': purchase.purchaseID,
      'transactionDate': purchase.transactionDate,
      'status': purchase.status.toString(),
      'token': token,
      'platform': platform,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  DateTime _calculateExpiryDate(String productId) {
    if (productId == yearlySubscriptionId) {
      return DateTime.now().add(const Duration(days: 365));
    } else if (productId == quarterlySubscriptionId) {
      return DateTime.now().add(const Duration(days: 90));
    } else {
      return DateTime.now().add(const Duration(days: 30));
    }
  }

  void _handleError(IAPError error) {
    if (kDebugMode) print('Purchase error: ${error.message}');
  }

  Future<void> _saveSubscriptionState(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_subscription_id', productId);
    await prefs.setString(
      'subscription_start_date',
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> _checkLocalSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final subId = prefs.getString('active_subscription_id');
    final startDateStr = prefs.getString('subscription_start_date');

    if (subId != null && startDateStr != null) {
      // ignore: unused_local_variable
      final startDate = DateTime.parse(startDateStr);
      final expiryDate = _calculateExpiryDate(subId);

      if (DateTime.now().isAfter(expiryDate)) {
        // Subscription expired locally, but we should verify with backend/store
        // For now, clear it
        await prefs.remove('active_subscription_id');
      }
    }
  }

  Future<bool> hasActiveSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;

      final data = doc.data();
      final isPremium = data?['isPremium'] ?? false;
      if (!isPremium) return false;

      final expiryDate = (data?['subscriptionExpiryDate'] as Timestamp?)
          ?.toDate();
      if (expiryDate == null) return false;

      return DateTime.now().isBefore(expiryDate);
    } catch (e) {
      return false;
    }
  }

  /// Get subscription info
  Future<Map<String, dynamic>?> getSubscriptionInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data();
      final isPremium = data?['isPremium'] ?? false;

      if (!isPremium) return null;

      return {
        'isPremium': isPremium,
        'subscriptionType': data?['subscriptionType'],
        'expiryDate': (data?['subscriptionExpiryDate'] as Timestamp?)?.toDate(),
        'startDate': (data?['subscriptionStartDate'] as Timestamp?)?.toDate(),
      };
    } catch (e) {
      if (kDebugMode) print('Error getting subscription info: $e');
      return null;
    }
  }

  /// Get product by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<void> _revokeSubscription(String uid) async {
    try {
      // 1. Update Firestore — remove premium access
      await _firestore.collection('users').doc(uid).update({
        'isPremium': false,
        'subscriptionStatus': 'expired',
        'featuresAccess': {'games': false, 'kegel': false, 'chat': false},
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Clear local SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_subscription_id');
      await prefs.remove('subscription_start_date');
      await prefs.remove('android_purchase_token');

      // 3. Notify user
      final langCode = prefs.getString('preferred_language') ?? 'en';
      final l10n = AppLocalizations(Locale(langCode));

      NotificationService().addInAppNotification(
        title: "Subscription Expired", // Add this key to your l10n
        body:
            "Subscription Expired you can purchase again,.", // Add this key to your l10n
        type: 'subscription',
      );

      if (kDebugMode) print('⚠️ Subscription revoked for user: $uid');
    } catch (e) {
      if (kDebugMode) print('Error revoking subscription: $e');
    }
  }
}
