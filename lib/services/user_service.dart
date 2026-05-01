import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velmora/services/notification_service.dart';


/// UserService handles all user-related Firestore operations
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID - note: needs to be handled carefully because SharedPreferences is async.
  /// For now, we prefer Firebase Auth if available, then local storage.
  String? get currentUserId => _auth.currentUser?.uid;

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('uid') ?? currentUserId;
  }

  /// Get user document reference
  DocumentReference get _userDoc =>
      _firestore.collection('users').doc(currentUserId);

  /// Get user stream for real-time updates
  Stream<DocumentSnapshot?> get userStream => _userDoc.snapshots();

  /// Get user data once
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final doc = await _userDoc.get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      throw 'Failed to fetch user data: $e';
    }
  }

  /// Update user display name
  Future<void> updateDisplayName(String name) async {
    try {
      await _userDoc.update({
        'displayName': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update name: $e';
    }
  }

  /// Update user password inside Firestore
  Future<void> updateUserPassword(String newPassword) async {
    try {
      await _userDoc.update({
        'password': newPassword,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update password in database: $e';
    }
  }

  /// Update preferred language
  Future<void> updateLanguage(String languageCode) async {
    try {
      await _userDoc.update({
        'preferredLanguage': languageCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update language: $e';
    }
  }



  /// Start free trial (stored in Firestore)
  Future<void> startTrial() async {
    try {
      final now = DateTime.now();
      final trialEnd = now.add(const Duration(hours: 48));

      await _userDoc.update({
        'subscriptionStatus': 'trial',
        'trialStartTime': Timestamp.fromDate(now),
        'trialEndTime': Timestamp.fromDate(trialEnd),
        'isPremium': false, // Ensure isPremium is false for trial
        'hasUsed48HourTrial': true, // Mark trial as used
        'updatedAt': FieldValue.serverTimestamp(),
      });

      NotificationService().addInAppNotification(
        title: '48-Hour Trial Started',
        body: 'Enjoy full access to all premium features for 48 hours!',
        type: 'trial',
      );
    } catch (e) {
      throw 'Failed to start trial: $e';
    }
  }

  /// Check if user is in trial period (from Firestore)
  Future<bool> isTrialActive() async {
    try {
      final userData = await getUserData();
      if (userData == null) return false;

      final status = userData['subscriptionStatus'];
      if (status != 'trial') return false;

      final trialEnd = userData['trialEndTime'] as Timestamp?;
      if (trialEnd == null) return false;

      return DateTime.now().isBefore(trialEnd.toDate());
    } catch (e) {
      return false;
    }
  }

  /// Get trial time remaining (from Firestore)
  Future<Duration?> getTrialTimeRemaining() async {
    try {
      final userData = await getUserData();
      if (userData == null) return null;

      final trialEnd = userData['trialEndTime'] as Timestamp?;
      if (trialEnd == null) return null;

      final remaining = trialEnd.toDate().difference(DateTime.now());
      return remaining.isNegative ? Duration.zero : remaining;
    } catch (e) {
      return null;
    }
  }

  /// Check if user has ever used trial (from Firestore)
  Future<bool> hasUsedTrial() async {
    try {
      final userData = await getUserData();
      return userData?['hasUsed48HourTrial'] ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get subscription status
  Future<String> getSubscriptionStatus() async {
    try {
      final userData = await getUserData();
      return userData?['subscriptionStatus'] ?? 'free';
    } catch (e) {
      return 'free';
    }
  }

  /// Check feature access
  Future<Map<String, bool>> getFeatureAccess() async {
    try {
      final userData = await getUserData();
      final access = userData?['featuresAccess'] as Map<String, dynamic>?;

      // Default access for free users
      if (access == null) {
        return {'games': false, 'kegel': false, 'chat': false};
      }

      return {
        'games': access['games'] ?? false,
        'kegel': access['kegel'] ?? false,
        'chat': access['chat'] ?? false,
      };
    } catch (e) {
      return {'games': false, 'kegel': false, 'chat': false};
    }
  }

  /// Update subscription to premium
  Future<void> upgradeToPremium() async {
    try {
      final now = DateTime.now();
      final oneYearLater = now.add(const Duration(days: 365));

      await _userDoc.update({
        'subscriptionStatus': 'premium',
        'isPremium': true,
        'subscriptionType': 'premium_test_dummy',
        'subscriptionExpiryDate': Timestamp.fromDate(oneYearLater),
        'featuresAccess': {'games': true, 'kegel': true, 'chat': true},
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to upgrade: $e';
    }
  }

  /// Get welcome message with user name
  Future<String> getWelcomeMessage() async {
    try {
      final userData = await getUserData();
      final name = userData?['displayName'] ?? '';

      if (name.isEmpty) {
        return 'Welcome\nBack';
      }

      return 'Welcome\n$name';
    } catch (e) {
      return 'Welcome\nBack';
    }
  }

  /// Delete all user data from Firestore and Storage
  Future<void> deleteUserData() async {
    final userId = currentUserId;
    if (userId == null) throw 'User not authenticated';

    try {
      // 1. Delete game content views sub-collection
      final gameViews = await _userDoc.collection('game_content_views').get();
      for (var doc in gameViews.docs) {
        await doc.reference.delete();
      }

      // 3. Delete user document
      await _userDoc.delete();
    } catch (e) {
      throw 'Failed to delete user data: $e';
    }
  }
}
