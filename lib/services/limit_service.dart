import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class LimitService {
  static final LimitService _instance = LimitService._internal();
  factory LimitService() => _instance;
  LimitService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Free tier limits
  static const int FREE_DAILY_AI_MESSAGES = 3;

  /// Check if user can send AI message
  Future<bool> canSendAIMessage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if user is premium
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data();
      final isPremium = data?['isPremium'] ?? false;

      bool isTrialActive = false;
      if (data?['subscriptionStatus'] == 'trial') {
        final trialEnd = data?['trialEndTime'] as Timestamp?;
        if (trialEnd != null && DateTime.now().isBefore(trialEnd.toDate())) {
          isTrialActive = true;
        }
      }

      // Premium and active trial users have unlimited messages
      if (isPremium || isTrialActive) return true;

      // Check daily limit for free users
      final today = _getTodayString();
      final limitDoc = await _firestore
          .collection('user_daily_limits')
          .doc('${user.uid}_$today')
          .get();

      if (!limitDoc.exists) {
        return true; // No messages sent today
      }

      final messageCount = limitDoc.data()?['aiMessageCount'] ?? 0;
      return messageCount < FREE_DAILY_AI_MESSAGES;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking AI message limit: $e');
      }
      return false;
    }
  }

  /// Get remaining AI messages for today
  Future<int> getRemainingAIMessages() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      // Check if user is premium
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data();
      final isPremium = data?['isPremium'] ?? false;

      bool isTrialActive = false;
      if (data?['subscriptionStatus'] == 'trial') {
        final trialEnd = data?['trialEndTime'] as Timestamp?;
        if (trialEnd != null && DateTime.now().isBefore(trialEnd.toDate())) {
          isTrialActive = true;
        }
      }

      // Premium and active trial users have unlimited messages
      if (isPremium || isTrialActive) return -1; // -1 indicates unlimited

      // Check daily limit for free users
      final today = _getTodayString();
      final limitDoc = await _firestore
          .collection('user_daily_limits')
          .doc('${user.uid}_$today')
          .get();

      if (!limitDoc.exists) {
        return FREE_DAILY_AI_MESSAGES;
      }

      final messageCount = limitDoc.data()?['aiMessageCount'] ?? 0;
      final remaining = FREE_DAILY_AI_MESSAGES - messageCount;
      return (remaining > 0 ? remaining : 0).toInt();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting remaining AI messages: $e');
      }
      return 0;
    }
  }

  /// Increment AI message count
  Future<void> incrementAIMessageCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if user is premium
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data();
      final isPremium = data?['isPremium'] ?? false;

      bool isTrialActive = false;
      if (data?['subscriptionStatus'] == 'trial') {
        final trialEnd = data?['trialEndTime'] as Timestamp?;
        if (trialEnd != null && DateTime.now().isBefore(trialEnd.toDate())) {
          isTrialActive = true;
        }
      }

      // Don't track for premium or active trial users
      if (isPremium || isTrialActive) return;

      final today = _getTodayString();
      final docId = '${user.uid}_$today';

      await _firestore.collection('user_daily_limits').doc(docId).update({
        'userId': user.uid,
        'date': today,
        'aiMessageCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error incrementing AI message count: $e');
      }
    }
  }

  /// Get current AI message count for today
  Future<int> getTodayAIMessageCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final today = _getTodayString();
      final limitDoc = await _firestore
          .collection('user_daily_limits')
          .doc('${user.uid}_$today')
          .get();

      if (!limitDoc.exists) return 0;

      return limitDoc.data()?['aiMessageCount'] ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting today AI message count: $e');
      }
      return 0;
    }
  }

  /// Check if limit is reached
  Future<bool> isLimitReached() async {
    final remaining = await getRemainingAIMessages();
    return remaining == 0;
  }

  /// Get time until reset (in hours)
  int getHoursUntilReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final difference = tomorrow.difference(now);
    return difference.inHours;
  }

  /// Get formatted reset time
  String getResetTimeFormatted() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final difference = tomorrow.difference(now);

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} and $minutes minute${minutes > 1 ? 's' : ''}';
    } else {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  /// Reset daily limits (called by Cloud Function)
  Future<void> resetDailyLimits() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final today = _getTodayString();
      final docId = '${user.uid}_$today';

      await _firestore.collection('user_daily_limits').doc(docId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting daily limits: $e');
      }
    }
  }

  /// Get today's date string (YYYY-MM-DD)
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Stream of remaining messages
  Stream<int> remainingMessagesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    final today = _getTodayString();
    final docId = '${user.uid}_$today';

    return _firestore
        .collection('user_daily_limits')
        .doc(docId)
        .snapshots()
        .asyncMap((snapshot) async {
          // Check if user is premium
          final userDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get();
          final data = userDoc.data();
          final isPremium = data?['isPremium'] ?? false;

          bool isTrialActive = false;
          if (data?['subscriptionStatus'] == 'trial') {
            final trialEnd = data?['trialEndTime'] as Timestamp?;
            if (trialEnd != null &&
                DateTime.now().isBefore(trialEnd.toDate())) {
              isTrialActive = true;
            }
          }

          if (isPremium || isTrialActive) return -1; // Unlimited

          if (!snapshot.exists) return FREE_DAILY_AI_MESSAGES;

          final messageCount = snapshot.data()?['aiMessageCount'] ?? 0;
          final remaining = FREE_DAILY_AI_MESSAGES - messageCount;
          return (remaining > 0 ? remaining : 0).toInt();
        });
  }
}
