import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class RateLimitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // Rate limit configurations
  static const int FREE_AI_MESSAGES_PER_DAY = 3;
  static const int PREMIUM_AI_MESSAGES_PER_DAY = 100;
  static const int GAME_PLAYS_PER_HOUR = 10;
  static const int KEGEL_SESSIONS_PER_DAY = 20;
  static const int PROFILE_UPDATES_PER_HOUR = 5;
  static const int SUPPORT_MESSAGES_PER_DAY = 3;

  /// Check if action is rate limited
  Future<RateLimitResult> checkRateLimit(
    String action, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (_userId.isEmpty) {
        return RateLimitResult(
          allowed: false,
          reason: 'User not authenticated',
          retryAfter: null,
        );
      }

      switch (action) {
        case 'ai_message':
          return await _checkAIMessageLimit();
        case 'game_play':
          return await _checkGamePlayLimit();
        case 'kegel_session':
          return await _checkKegelSessionLimit();
        case 'profile_update':
          return await _checkProfileUpdateLimit();
        case 'support_message':
          return await _checkSupportMessageLimit();
        default:
          return RateLimitResult(allowed: true);
      }
    } catch (e) {
      print('Error checking rate limit: $e');
      // Allow action on error to prevent blocking users
      return RateLimitResult(allowed: true);
    }
  }

  /// Record action for rate limiting
  Future<void> recordAction(
    String action, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (_userId.isEmpty) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final currentHour = DateTime(now.year, now.month, now.day, now.hour);

      await _firestore
          .collection('rate_limits')
          .doc(_userId)
          .collection('actions')
          .add({
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
        'date': Timestamp.fromDate(today),
        'hour': Timestamp.fromDate(currentHour),
        'metadata': metadata ?? {},
      });

      // Update counter
      await _updateCounter(action, today, currentHour);
    } catch (e) {
      print('Error recording action: $e');
    }
  }

  /// Check AI message rate limit
  Future<RateLimitResult> _checkAIMessageLimit() async {
    try {
      // Check if user is premium or trial is active
      final userDoc = await _firestore.collection('users').doc(_userId).get();
      final data = userDoc.data();
      bool isPremium = data?['isPremium'] ?? false;

      if (!isPremium && data?['subscriptionStatus'] == 'trial') {
        final trialEnd = data?['trialEndTime'] as Timestamp?;
        if (trialEnd != null && DateTime.now().isBefore(trialEnd.toDate())) {
          isPremium = true; // treat trial as premium
        }
      }

      final limit = isPremium ? PREMIUM_AI_MESSAGES_PER_DAY : FREE_AI_MESSAGES_PER_DAY;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = '${today.year}-${today.month}-${today.day}';

      final counterDoc = await _firestore
          .collection('rate_limits')
          .doc(_userId)
          .collection('counters')
          .doc('ai_message_$todayStr')
          .get();

      final count = counterDoc.data()?['count'] ?? 0;

      if (count >= limit) {
        final tomorrow = today.add(const Duration(days: 1));
        return RateLimitResult(
          allowed: false,
          reason: isPremium
              ? 'Daily AI message limit reached ($limit messages)'
              : 'Daily AI message limit reached. Upgrade to Premium for unlimited messages!',
          retryAfter: tomorrow,
          currentCount: count,
          limit: limit,
        );
      }

      return RateLimitResult(
        allowed: true,
        currentCount: count,
        limit: limit,
      );
    } catch (e) {
      print('Error checking AI message limit: $e');
      return RateLimitResult(allowed: true);
    }
  }

  /// Check game play rate limit
  Future<RateLimitResult> _checkGamePlayLimit() async {
    try {
      final now = DateTime.now();
      final currentHour = DateTime(now.year, now.month, now.day, now.hour);
      final hourStr = '${currentHour.year}-${currentHour.month}-${currentHour.day}-${currentHour.hour}';

      final counterDoc = await _firestore
          .collection('rate_limits')
          .doc(_userId)
          .collection('counters')
          .doc('game_play_$hourStr')
          .get();

      final count = counterDoc.data()?['count'] ?? 0;

      if (count >= GAME_PLAYS_PER_HOUR) {
        final nextHour = currentHour.add(const Duration(hours: 1));
        return RateLimitResult(
          allowed: false,
          reason: 'Too many game plays. Please try again in a few minutes.',
          retryAfter: nextHour,
          currentCount: count,
          limit: GAME_PLAYS_PER_HOUR,
        );
      }

      return RateLimitResult(
        allowed: true,
        currentCount: count,
        limit: GAME_PLAYS_PER_HOUR,
      );
    } catch (e) {
      print('Error checking game play limit: $e');
      return RateLimitResult(allowed: true);
    }
  }

  /// Check kegel session rate limit
  Future<RateLimitResult> _checkKegelSessionLimit() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = '${today.year}-${today.month}-${today.day}';

      final counterDoc = await _firestore
          .collection('rate_limits')
          .doc(_userId)
          .collection('counters')
          .doc('kegel_session_$todayStr')
          .get();

      final count = counterDoc.data()?['count'] ?? 0;

      if (count >= KEGEL_SESSIONS_PER_DAY) {
        final tomorrow = today.add(const Duration(days: 1));
        return RateLimitResult(
          allowed: false,
          reason: 'Daily kegel session limit reached. Rest is important too!',
          retryAfter: tomorrow,
          currentCount: count,
          limit: KEGEL_SESSIONS_PER_DAY,
        );
      }

      return RateLimitResult(
        allowed: true,
        currentCount: count,
        limit: KEGEL_SESSIONS_PER_DAY,
      );
    } catch (e) {
      print('Error checking kegel session limit: $e');
      return RateLimitResult(allowed: true);
    }
  }

  /// Check profile update rate limit
  Future<RateLimitResult> _checkProfileUpdateLimit() async {
    try {
      final now = DateTime.now();
      final currentHour = DateTime(now.year, now.month, now.day, now.hour);
      final hourStr = '${currentHour.year}-${currentHour.month}-${currentHour.day}-${currentHour.hour}';

      final counterDoc = await _firestore
          .collection('rate_limits')
          .doc(_userId)
          .collection('counters')
          .doc('profile_update_$hourStr')
          .get();

      final count = counterDoc.data()?['count'] ?? 0;

      if (count >= PROFILE_UPDATES_PER_HOUR) {
        final nextHour = currentHour.add(const Duration(hours: 1));
        return RateLimitResult(
          allowed: false,
          reason: 'Too many profile updates. Please try again later.',
          retryAfter: nextHour,
          currentCount: count,
          limit: PROFILE_UPDATES_PER_HOUR,
        );
      }

      return RateLimitResult(
        allowed: true,
        currentCount: count,
        limit: PROFILE_UPDATES_PER_HOUR,
      );
    } catch (e) {
      print('Error checking profile update limit: $e');
      return RateLimitResult(allowed: true);
    }
  }

  /// Check support message rate limit
  Future<RateLimitResult> _checkSupportMessageLimit() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = '${today.year}-${today.month}-${today.day}';

      final counterDoc = await _firestore
          .collection('rate_limits')
          .doc(_userId)
          .collection('counters')
          .doc('support_message_$todayStr')
          .get();

      final count = counterDoc.data()?['count'] ?? 0;

      if (count >= SUPPORT_MESSAGES_PER_DAY) {
        final tomorrow = today.add(const Duration(days: 1));
        return RateLimitResult(
          allowed: false,
          reason: 'Daily support message limit reached. Please try again tomorrow.',
          retryAfter: tomorrow,
          currentCount: count,
          limit: SUPPORT_MESSAGES_PER_DAY,
        );
      }

      return RateLimitResult(
        allowed: true,
        currentCount: count,
        limit: SUPPORT_MESSAGES_PER_DAY,
      );
    } catch (e) {
      print('Error checking support message limit: $e');
      return RateLimitResult(allowed: true);
    }
  }

  /// Update counter for action
  Future<void> _updateCounter(String action, DateTime date, DateTime hour) async {
    try {
      String counterId;

      if (action == 'ai_message' || action == 'kegel_session' || action == 'support_message') {
        // Daily counters
        final dateStr = '${date.year}-${date.month}-${date.day}';
        counterId = '${action}_$dateStr';
      } else {
        // Hourly counters
        final hourStr = '${hour.year}-${hour.month}-${hour.day}-${hour.hour}';
        counterId = '${action}_$hourStr';
      }

      await _firestore
          .collection('rate_limits')
          .doc(_userId)
          .collection('counters')
          .doc(counterId)
          .set({
        'count': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
        'action': action,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating counter: $e');
    }
  }

  /// Get remaining actions for a specific limit
  Future<int> getRemainingActions(String action) async {
    try {
      final result = await checkRateLimit(action);
      if (result.limit == null) return -1; // Unlimited

      return result.limit! - (result.currentCount ?? 0);
    } catch (e) {
      print('Error getting remaining actions: $e');
      return -1;
    }
  }

  /// Get time until rate limit resets
  Future<Duration?> getTimeUntilReset(String action) async {
    try {
      final result = await checkRateLimit(action);
      if (result.retryAfter == null) return null;

      final now = DateTime.now();
      return result.retryAfter!.difference(now);
    } catch (e) {
      print('Error getting time until reset: $e');
      return null;
    }
  }

  /// Clean up old rate limit data (call periodically)
  Future<void> cleanupOldData() async {
    try {
      if (_userId.isEmpty) return;

      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      // Delete old actions
      final actionsQuery = await _firestore
          .collection('rate_limits')
          .doc(_userId)
          .collection('actions')
          .where('timestamp', isLessThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (var doc in actionsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete old counters
      final countersQuery = await _firestore
          .collection('rate_limits')
          .doc(_userId)
          .collection('counters')
          .where('lastUpdated', isLessThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      for (var doc in countersQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Cleaned up old rate limit data');
    } catch (e) {
      print('Error cleaning up old data: $e');
    }
  }

  /// Get rate limit statistics
  Future<Map<String, dynamic>> getRateLimitStats() async {
    try {
      if (_userId.isEmpty) return {};

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = '${today.year}-${today.month}-${today.day}';
      final currentHour = DateTime(now.year, now.month, now.day, now.hour);
      final hourStr = '${currentHour.year}-${currentHour.month}-${currentHour.day}-${currentHour.hour}';

      // Get all counters
      final aiMessageDoc = await _firestore
          .collection('rate_limits')
          .doc(_userId)
          .collection('counters')
          .doc('ai_message_$todayStr')
          .get();

      final gamePlayDoc = await _firestore
          .collection('rate_limits')
          .doc(_userId)
          .collection('counters')
          .doc('game_play_$hourStr')
          .get();

      final kegelSessionDoc = await _firestore
          .collection('rate_limits')
          .doc(_userId)
          .collection('counters')
          .doc('kegel_session_$todayStr')
          .get();

      final profileUpdateDoc = await _firestore
          .collection('rate_limits')
          .doc(_userId)
          .collection('counters')
          .doc('profile_update_$hourStr')
          .get();

      final supportMessageDoc = await _firestore
          .collection('rate_limits')
          .doc(_userId)
          .collection('counters')
          .doc('support_message_$todayStr')
          .get();

      // Check if premium or trial is active
      final userDoc = await _firestore.collection('users').doc(_userId).get();
      final data = userDoc.data();
      bool isPremium = data?['isPremium'] ?? false;

      if (!isPremium && data?['subscriptionStatus'] == 'trial') {
        final trialEnd = data?['trialEndTime'] as Timestamp?;
        if (trialEnd != null && DateTime.now().isBefore(trialEnd.toDate())) {
          isPremium = true; // treat trial as premium
        }
      }

      return {
        'aiMessages': {
          'used': aiMessageDoc.data()?['count'] ?? 0,
          'limit': isPremium ? PREMIUM_AI_MESSAGES_PER_DAY : FREE_AI_MESSAGES_PER_DAY,
          'period': 'daily',
        },
        'gamePlays': {
          'used': gamePlayDoc.data()?['count'] ?? 0,
          'limit': GAME_PLAYS_PER_HOUR,
          'period': 'hourly',
        },
        'kegelSessions': {
          'used': kegelSessionDoc.data()?['count'] ?? 0,
          'limit': KEGEL_SESSIONS_PER_DAY,
          'period': 'daily',
        },
        'profileUpdates': {
          'used': profileUpdateDoc.data()?['count'] ?? 0,
          'limit': PROFILE_UPDATES_PER_HOUR,
          'period': 'hourly',
        },
        'supportMessages': {
          'used': supportMessageDoc.data()?['count'] ?? 0,
          'limit': SUPPORT_MESSAGES_PER_DAY,
          'period': 'daily',
        },
      };
    } catch (e) {
      print('Error getting rate limit stats: $e');
      return {};
    }
  }
}

/// Rate limit result class
class RateLimitResult {
  final bool allowed;
  final String? reason;
  final DateTime? retryAfter;
  final int? currentCount;
  final int? limit;

  RateLimitResult({
    required this.allowed,
    this.reason,
    this.retryAfter,
    this.currentCount,
    this.limit,
  });

  int? get remaining => limit != null && currentCount != null
      ? limit! - currentCount!
      : null;
}
