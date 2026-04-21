import 'dart:math' show max;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// ErrorCacheService - Stores and retrieves errors for debugging
/// Prevents app crashes by caching errors instead of throwing
class ErrorCacheService {
  static final ErrorCacheService _instance = ErrorCacheService._internal();
  factory ErrorCacheService() => _instance;
  ErrorCacheService._internal();

  static const String _lastErrorKey = 'last_error';
  static const String _lastErrorStackKey = 'last_error_stack';
  static const String _lastErrorTimeKey = 'last_error_time';
  static const String _errorHistoryKey = 'error_history';
  static const String _crashCountKey = 'crash_count';

  /// Store the last error
  Future<void> storeError(
    String error,
    String stack, {
    String? location,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().toIso8601String();

      // Store individual fields
      await prefs.setString(_lastErrorKey, error);
      await prefs.setString(_lastErrorStackKey, stack);
      await prefs.setString(_lastErrorTimeKey, timestamp);
      if (location != null) {
        await prefs.setString('last_error_location', location);
      }

      // Add to error history
      final history = prefs.getStringList(_errorHistoryKey) ?? [];
      final historyEntry = '[$timestamp] $error${location != null ? ' @ $location' : ''}';
      if (history.length >= 50) {
        history.removeAt(0); // Keep only last 50 errors
      }
      history.add(historyEntry);
      await prefs.setStringList(_errorHistoryKey, history);

      // Increment crash count
      final crashCount = prefs.getInt(_crashCountKey) ?? 0;
      await prefs.setInt(_crashCountKey, crashCount + 1);

      debugPrint('💾 [ErrorCache] Error stored: $error');
      if (location != null) {
        debugPrint('💾 [ErrorCache] Location: $location');
      }
    } catch (e) {
      debugPrint('❌ [ErrorCache] Failed to store error: $e');
    }
  }

  /// Retrieve the last error
  Future<Map<String, String?>> getLastError() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'error': prefs.getString(_lastErrorKey),
        'stack': prefs.getString(_lastErrorStackKey),
        'time': prefs.getString(_lastErrorTimeKey),
        'location': prefs.getString('last_error_location'),
      };
    } catch (e) {
      debugPrint('❌ [ErrorCache] Failed to retrieve last error: $e');
      return {};
    }
  }

  /// Get error history
  Future<List<String>> getErrorHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_errorHistoryKey) ?? [];
    } catch (e) {
      debugPrint('❌ [ErrorCache] Failed to retrieve error history: $e');
      return [];
    }
  }

  /// Get crash count
  Future<int> getCrashCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_crashCountKey) ?? 0;
    } catch (e) {
      debugPrint('❌ [ErrorCache] Failed to retrieve crash count: $e');
      return 0;
    }
  }

  /// Clear all cached errors
  Future<void> clearErrors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastErrorKey);
      await prefs.remove(_lastErrorStackKey);
      await prefs.remove(_lastErrorTimeKey);
      await prefs.remove('last_error_location');
      await prefs.remove(_errorHistoryKey);
      await prefs.remove(_crashCountKey);
      debugPrint('✅ [ErrorCache] All errors cleared');
    } catch (e) {
      debugPrint('❌ [ErrorCache] Failed to clear errors: $e');
    }
  }

  /// Log error with full context (for game services)
  Future<void> logGameError({
    required String gameId,
    required String phase,
    required String error,
    required String stack,
  }) async {
    final location = 'Game: $gameId, Phase: $phase';
    debugPrint('❌ [GAME ERROR] $location');
    debugPrint('❌ [GAME ERROR] Error: $error');
    debugPrint('❌ [GAME ERROR] Stack: $stack');
    await storeError(error, stack, location: location);
  }

  /// Print diagnostic info
  Future<void> printDiagnostics() async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [ErrorCache] DIAGNOSTIC REPORT');
    debugPrint('═══════════════════════════════════════════════════════');

    final lastError = await getLastError();
    if (lastError['error'] != null) {
      debugPrint('📛 Last Error: ${lastError['error']}');
      debugPrint('📍 Location: ${lastError['location'] ?? 'Unknown'}');
      debugPrint('🕐 Time: ${lastError['time'] ?? 'Unknown'}');
      debugPrint('📜 Stack: ${lastError['stack']?.substring(0, 200)}...');
    } else {
      debugPrint('✅ No cached errors found');
    }

    final crashCount = await getCrashCount();
    debugPrint('💥 Total crash count: $crashCount');

    final history = await getErrorHistory();
    if (history.isNotEmpty) {
      debugPrint('📋 Recent error history:');
      for (int i = history.length - 1; i >= max(0, history.length - 5); i--) {
        debugPrint('   ${history[i]}');
      }
    }

    debugPrint('═══════════════════════════════════════════════════════');
  }
}
