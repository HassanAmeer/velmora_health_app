import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  final FirebasePerformance _performance = FirebasePerformance.instance;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseAnalyticsObserver getAnalyticsObserver() =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Initialize analytics services
  Future<void> initialize() async {
    try {
      // Enable analytics collection
      await _analytics.setAnalyticsCollectionEnabled(true);

      // Configure Crashlytics
      FlutterError.onError = _crashlytics.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };

      // Enable performance monitoring
      await _performance.setPerformanceCollectionEnabled(true);

      if (kDebugMode) {
        print('Analytics services initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing analytics: $e');
      }
    }
  }

  /// Set user properties
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      await _crashlytics.setUserIdentifier(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user ID: $e');
      }
    }
  }

  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user property: $e');
      }
    }
  }

  /// Log custom events
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters?.cast<String, Object>(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error logging event: $e');
      }
    }
  }

  /// Screen tracking
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error logging screen view: $e');
      }
    }
  }

  /// Authentication events
  Future<void> logLogin(String method) async {
    await logEvent('login', parameters: {'method': method});
  }

  Future<void> logSignUp(String method) async {
    await logEvent('sign_up', parameters: {'method': method});
  }

  Future<void> logLogout() async {
    await logEvent('logout');
  }

  /// Game events
  Future<void> logGameStart(String gameId, String gameName) async {
    await logEvent('game_start', parameters: {
      'game_id': gameId,
      'game_name': gameName,
    });
  }

  Future<void> logGameComplete(String gameId, String gameName, int duration) async {
    await logEvent('game_complete', parameters: {
      'game_id': gameId,
      'game_name': gameName,
      'duration_seconds': duration,
    });
  }

  /// Chat events
  Future<void> logChatMessage(bool isAI, int messageLength) async {
    await logEvent('chat_message', parameters: {
      'is_ai': isAI ? 1 : 0,
      'message_length': messageLength,
    });
  }

  Future<void> logAILimitReached() async {
    await logEvent('ai_limit_reached');
  }

  /// Subscription events
  Future<void> logSubscriptionStart(String plan, double price) async {
    await logEvent('subscription_start', parameters: {
      'plan': plan,
      'price': price,
      'currency': 'USD',
    });
  }

  Future<void> logSubscriptionCancel(String plan) async {
    await logEvent('subscription_cancel', parameters: {
      'plan': plan,
    });
  }

  Future<void> logTrialStart() async {
    await logEvent('trial_start');
  }

  Future<void> logTrialConversion(String plan) async {
    await logEvent('trial_conversion', parameters: {
      'plan': plan,
    });
  }

  /// Kegel exercise events
  Future<void> logKegelExerciseStart(String level) async {
    await logEvent('kegel_start', parameters: {
      'level': level,
    });
  }

  Future<void> logKegelExerciseComplete(String level, int duration, int reps) async {
    await logEvent('kegel_complete', parameters: {
      'level': level,
      'duration_seconds': duration,
      'repetitions': reps,
    });
  }

  /// Settings events
  Future<void> logLanguageChange(String language) async {
    await logEvent('language_change', parameters: {
      'language': language,
    });
  }

  Future<void> logNotificationToggle(bool enabled) async {
    await logEvent('notification_toggle', parameters: {
      'enabled': enabled ? 1 : 0,
    });
  }

  /// Error tracking
  Future<void> logError(dynamic error, StackTrace? stackTrace, {String? reason}) async {
    try {
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error logging error: $e');
      }
    }
  }

  Future<void> logMessage(String message) async {
    try {
      await _crashlytics.log(message);
    } catch (e) {
      if (kDebugMode) {
        print('Error logging message: $e');
      }
    }
  }

  /// Performance monitoring
  Future<T> tracePerformance<T>(String traceName, Future<T> Function() operation) async {
    final trace = _performance.newTrace(traceName);
    await trace.start();

    try {
      final result = await operation();
      await trace.stop();
      return result;
    } catch (e) {
      await trace.stop();
      rethrow;
    }
  }

  /// HTTP request tracking
  HttpMetric newHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }

  /// Custom metrics
  Future<void> setCustomMetric(String traceName, String metricName, int value) async {
    try {
      final trace = _performance.newTrace(traceName);
      await trace.start();
      trace.setMetric(metricName, value);
      await trace.stop();
    } catch (e) {
      if (kDebugMode) {
        print('Error setting custom metric: $e');
      }
    }
  }
}
