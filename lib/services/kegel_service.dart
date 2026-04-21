import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velmora/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velmora/services/rate_limit_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KegelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RateLimitService _rateLimitService = RateLimitService();

  String get _userId => _auth.currentUser?.uid ?? '';

  // Local storage keys
  static const String _dailyCompletionsKey = 'kegel_daily_completions_';

  /// Get user kegel data from Firebase
  Future<Map<String, dynamic>?> getKegelData() async {
    try {
      if (_userId.isEmpty) return null;

      final doc = await _firestore.collection('users').doc(_userId).get();
      if (!doc.exists) return null;

      final data = doc.data();
      return data?['kegel'] as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting kegel data: $e');
      return null;
    }
  }

  /// Get today's date string (YYYY-MM-DD)
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Get local storage key for today's completions
  String _getTodayCompletionsKey() =>
      '$_dailyCompletionsKey${_getTodayString()}';

  /// Check if user completed daily kegel goal (local storage - resets daily)
  Future<bool> hasCompletedDailyGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayString();
      final completedDates = prefs.getStringList('kegel_completed_dates') ?? [];

      // Check if today's date is in the completed dates
      return completedDates.any((date) => date == today);
    } catch (e) {
      print('Error checking daily goal: $e');
      return false;
    }
  }

  /// Save daily goal completion to local storage (resets daily)
  Future<void> saveDailyGoalCompletion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayString();

      // Get existing completed dates
      final completedDates = prefs.getStringList('kegel_completed_dates') ?? [];

      // Add today if not already present
      if (!completedDates.any((date) => date == today)) {
        completedDates.add(today);
        await prefs.setStringList('kegel_completed_dates', completedDates);
      }

      // Increment daily completion count
      final todayKey = _getTodayCompletionsKey();
      final currentCount = prefs.getInt(todayKey) ?? 0;
      await prefs.setInt(todayKey, currentCount + 1);
    } catch (e) {
      print('Error saving daily goal: $e');
    }
  }

  /// Get today's kegel completion count (local storage)
  Future<int> getTodayCompletionCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = _getTodayCompletionsKey();
      return prefs.getInt(todayKey) ?? 0;
    } catch (e) {
      print('Error getting today count: $e');
      return 0;
    }
  }

  /// Reset daily limits (called at midnight or on app start)
  Future<void> resetDailyLimits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayString();

      // Clean up old dates (keep only today)
      final completedDates = prefs.getStringList('kegel_completed_dates') ?? [];
      final updatedDates = completedDates
          .where((date) => date == today)
          .toList();
      await prefs.setStringList('kegel_completed_dates', updatedDates);

      // Remove old daily counts (older than 7 days)
      for (int i = 1; i <= 7; i++) {
        final oldDate = DateTime.now().subtract(Duration(days: i));
        final oldDateStr =
            '${oldDate.year}-${oldDate.month.toString().padLeft(2, '0')}-${oldDate.day.toString().padLeft(2, '0')}';
        final oldKey = '$_dailyCompletionsKey$oldDateStr';
        await prefs.remove(oldKey);
      }
    } catch (e) {
      print('Error resetting daily limits: $e');
    }
  }

  /// Save kegel session to Firestore (for admin viewing - historical data)
  Future<void> saveSessionToFirestore({
    required String routineType,
    required int durationMinutes,
    required int setsCompleted,
  }) async {
    try {
      if (_userId.isEmpty) return;

      final now = DateTime.now();
      final today = _getTodayString();

      // Save to daily completions collection (for admin viewing)
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('kegel_daily_completions')
          .doc(today)
          .set({
            'date': today,
            'completions': FieldValue.increment(1),
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Also save detailed session log
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('kegel_sessions')
          .add({
            'routineType': routineType,
            'durationMinutes': durationMinutes,
            'setsCompleted': setsCompleted,
            'completedAt': Timestamp.fromDate(now),
            'date': today,
          });

      NotificationService().addInAppNotification(
        title: 'Kegel Routine Complete',
        body:
            'Great job completing your $routineType ($durationMinutes minutes).',
        type: 'kegel',
      );
    } catch (e) {
      print('Error saving to Firestore: $e');
    }
  }

  /// Save kegel session completion (called when exercise completes)
  Future<void> saveSession({
    required String routineType,
    required int durationMinutes,
    required int setsCompleted,
  }) async {
    try {
      if (_userId.isEmpty) return;

      // Check rate limit
      final rateLimitResult = await _rateLimitService.checkRateLimit(
        'kegel_session',
      );
      if (!rateLimitResult.allowed) {
        throw rateLimitResult.reason ?? 'Rate limit exceeded';
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // ========== LOCAL STORAGE (Daily limits - resets daily) ==========
      // Save to local storage for daily goal tracking (resets at midnight)
      await saveDailyGoalCompletion();

      // ========== FIRESTORE (Historical data - for admin viewing) ==========
      // Save to Firestore for permanent historical record
      await saveSessionToFirestore(
        routineType: routineType,
        durationMinutes: durationMinutes,
        setsCompleted: setsCompleted,
      );

      // ========== FIRESTORE (User profile data) ==========
      // Get current kegel data
      final currentData = await getKegelData();

      int weekStreak = currentData?['weekStreak'] ?? 0;
      int totalCompleted = currentData?['totalCompleted'] ?? 0;
      int longestStreak = currentData?['longestStreak'] ?? 0;
      int totalMinutes = currentData?['totalMinutes'] ?? 0;
      List<dynamic> completedDates = currentData?['completedDates'] ?? [];
      List<dynamic> achievements = currentData?['achievements'] ?? [];
      DateTime? lastCompletedDate = currentData?['lastCompletedDate'] != null
          ? (currentData!['lastCompletedDate'] as Timestamp).toDate()
          : null;

      // Check if already completed today (for streak calculation)
      bool alreadyCompletedToday = completedDates.any((date) {
        final d = (date as Timestamp).toDate();
        return d.year == today.year &&
            d.month == today.month &&
            d.day == today.day;
      });

      if (!alreadyCompletedToday) {
        totalCompleted++;
        totalMinutes += durationMinutes;
        completedDates.add(Timestamp.fromDate(today));

        // Calculate streak
        if (lastCompletedDate != null) {
          final difference = today.difference(lastCompletedDate).inDays;
          if (difference == 1) {
            weekStreak++;
          } else if (difference > 1) {
            weekStreak = 1;
          }
        } else {
          weekStreak = 1;
        }

        // Update longest streak
        if (weekStreak > longestStreak) {
          longestStreak = weekStreak;
        }

        // Check for new achievements
        final newAchievements = _checkAchievements(
          totalCompleted,
          weekStreak,
          longestStreak,
          totalMinutes,
          achievements,
        );
        achievements = newAchievements;
      }

      // Calculate daily goal percentage
      final dailyGoalPercent = _calculateDailyGoal(completedDates);

      // Calculate 30-day plan progress
      final planProgress = _calculate30DayProgress(
        completedDates,
        currentData?['challengeStartedAt'],
      );

      Map<String, dynamic> updateData = {
        'weekStreak': weekStreak,
        'longestStreak': longestStreak,
        'totalCompleted': totalCompleted,
        'totalMinutes': totalMinutes,
        'completedDates': completedDates,
        'lastCompletedDate': Timestamp.fromDate(today),
        'dailyGoalPercent': dailyGoalPercent,
        'lastRoutineType': routineType,
        'lastSessionDuration': durationMinutes,
        'lastSessionDate': Timestamp.fromDate(now),
        'achievements': achievements,
        'planProgress': planProgress,
        'dailyCompletionsToday': FieldValue.increment(1),
      };

      // Set start date if not already set
      if (currentData?['challengeStartedAt'] == null &&
          !alreadyCompletedToday) {
        updateData['challengeStartedAt'] = Timestamp.fromDate(today);
      }

      await _firestore.collection('users').doc(_userId).update({
        'kegel': updateData,
      });

      // Record rate limit action
      await _rateLimitService.recordAction(
        'kegel_session',
        metadata: {
          'routineType': routineType,
          'durationMinutes': durationMinutes,
          'setsCompleted': setsCompleted,
        },
      );
    } catch (e) {
      print('Error saving kegel session: $e');
      rethrow;
    }
  }

  /// Calculate daily goal percentage based on weekly completion
  double _calculateDailyGoal(List<dynamic> completedDates) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    int thisWeekCompletions = 0;
    for (var date in completedDates) {
      final d = (date as Timestamp).toDate();
      if (d.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          d.isBefore(now.add(const Duration(days: 1)))) {
        thisWeekCompletions++;
      }
    }

    // Goal: 3 sessions per week = ~43% per session
    return (thisWeekCompletions / 7 * 100).clamp(0, 100);
  }

  /// Calculate 30-day plan progress (fixed-start based)
  int _calculate30DayProgress(
    List<dynamic> completedDates,
    dynamic challengeStartedAt,
  ) {
    if (challengeStartedAt == null) return 0;

    final startDate = (challengeStartedAt as Timestamp).toDate();
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    Set<String> uniqueDays = {};

    for (var date in completedDates) {
      final d = (date as Timestamp).toDate();
      final normalizedD = DateTime(d.year, d.month, d.day);

      if (!normalizedD.isBefore(normalizedStart)) {
        uniqueDays.add(
          '${normalizedD.year}-${normalizedD.month}-${normalizedD.day}',
        );
      }
    }

    return uniqueDays.length.clamp(0, 30);
  }

  /// Check and award achievements
  List<dynamic> _checkAchievements(
    int totalCompleted,
    int currentStreak,
    int longestStreak,
    int totalMinutes,
    List<dynamic> existingAchievements,
  ) {
    final achievements = List<String>.from(existingAchievements);

    // First exercise
    if (totalCompleted >= 1 && !achievements.contains('first_exercise')) {
      achievements.add('first_exercise');
    }

    // 7-day streak
    if (currentStreak >= 7 && !achievements.contains('week_warrior')) {
      achievements.add('week_warrior');
    }

    // 30-day streak
    if (currentStreak >= 30 && !achievements.contains('month_master')) {
      achievements.add('month_master');
    }

    // 100 exercises
    if (totalCompleted >= 100 && !achievements.contains('century_club')) {
      achievements.add('century_club');
    }

    // 500 minutes
    if (totalMinutes >= 500 && !achievements.contains('time_champion')) {
      achievements.add('time_champion');
    }

    // Longest streak 14 days
    if (longestStreak >= 14 && !achievements.contains('streak_legend')) {
      achievements.add('streak_legend');
    }

    return achievements;
  }

  /// Get achievement details
  Map<String, dynamic> getAchievementDetails(String achievementId) {
    final achievements = {
      'first_exercise': {
        'title': 'First Steps',
        'description': 'Complete your first kegel exercise',
        'icon': '🎯',
        'color': 0xFF4CAF50,
      },
      'week_warrior': {
        'title': 'Week Warrior',
        'description': 'Maintain a 7-day streak',
        'icon': '🔥',
        'color': 0xFFFF9800,
      },
      'month_master': {
        'title': 'Month Master',
        'description': 'Maintain a 30-day streak',
        'icon': '👑',
        'color': 0xFFFFD700,
      },
      'century_club': {
        'title': 'Century Club',
        'description': 'Complete 100 exercises',
        'icon': '💯',
        'color': 0xFF9C27B0,
      },
      'time_champion': {
        'title': 'Time Champion',
        'description': 'Exercise for 500 minutes total',
        'icon': '⏱️',
        'color': 0xFF2196F3,
      },
      'streak_legend': {
        'title': 'Streak Legend',
        'description': 'Achieve a 14-day longest streak',
        'icon': '⚡',
        'color': 0xFFE91E63,
      },
    };

    return achievements[achievementId] ?? {};
  }

  /// Get all available achievements
  List<Map<String, dynamic>> getAllAchievements() {
    return [
      getAchievementDetails('first_exercise'),
      getAchievementDetails('week_warrior'),
      getAchievementDetails('month_master'),
      getAchievementDetails('century_club'),
      getAchievementDetails('time_champion'),
      getAchievementDetails('streak_legend'),
    ];
  }

  /// Get weekly progress data for chart
  Future<List<Map<String, dynamic>>> getWeeklyProgress() async {
    try {
      final kegelData = await getKegelData();
      if (kegelData == null) return [];

      final completedDates =
          kegelData['completedDates'] as List<dynamic>? ?? [];
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));

      List<Map<String, dynamic>> weekData = [];

      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        final dayDate = DateTime(day.year, day.month, day.day);

        bool completed = completedDates.any((date) {
          final d = (date as Timestamp).toDate();
          return d.year == dayDate.year &&
              d.month == dayDate.month &&
              d.day == dayDate.day;
        });

        weekData.add({
          'day': _getDayName(day.weekday),
          'date': dayDate,
          'completed': completed,
        });
      }

      return weekData;
    } catch (e) {
      print('Error getting weekly progress: $e');
      return [];
    }
  }

  /// Get monthly progress data for chart
  Future<List<Map<String, dynamic>>> getMonthlyProgress() async {
    try {
      final kegelData = await getKegelData();
      if (kegelData == null) return [];

      final completedDates =
          kegelData['completedDates'] as List<dynamic>? ?? [];
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

      List<Map<String, dynamic>> monthData = [];

      for (int i = 0; i < daysInMonth; i++) {
        final day = monthStart.add(Duration(days: i));

        bool completed = completedDates.any((date) {
          final d = (date as Timestamp).toDate();
          return d.year == day.year && d.month == day.month && d.day == day.day;
        });

        monthData.add({'day': day.day, 'date': day, 'completed': completed});
      }

      return monthData;
    } catch (e) {
      print('Error getting monthly progress: $e');
      return [];
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  /// Initialize kegel data for new users
  Future<void> initializeKegelData() async {
    try {
      if (_userId.isEmpty) return;

      final doc = await _firestore.collection('users').doc(_userId).get();
      if (!doc.exists || doc.data()?['kegel'] == null) {
        await _firestore.collection('users').doc(_userId).set({
          'kegel': {
            'weekStreak': 0,
            'longestStreak': 0,
            'totalCompleted': 0,
            'totalMinutes': 0,
            'completedDates': [],
            'dailyGoalPercent': 0.0,
            'lastCompletedDate': null,
            'lastRoutineType': '',
            'lastSessionDuration': 0,
            'lastSessionDate': null,
            'achievements': [],
            'planProgress': 0,
            'challengeStartedAt': null,
          },
        });
      }
    } catch (e) {
      print('Error initializing kegel data: $e');
    }
  }

  /// Reset challenge progress
  Future<void> resetChallenge() async {
    try {
      if (_userId.isEmpty) return;

      await _firestore.collection('users').doc(_userId).update({
        'kegel.challengeStartedAt': null,
        'kegel.planProgress': 0,
      });
    } catch (e) {
      print('Error resetting kegel challenge: $e');
    }
  }

  /// Get 30-day plan details
  Map<String, dynamic> get30DayPlan() {
    return {
      'title': '30-Day Kegel Challenge',
      'description': 'Complete exercises for 30 consecutive days',
      'goal': 30,
      'weeks': [
        {
          'week': 1,
          'title': 'Foundation Week',
          'description': 'Build the habit with beginner routines',
          'routine': 'beginner',
          'frequency': 'Daily',
        },
        {
          'week': 2,
          'title': 'Consistency Week',
          'description': 'Maintain daily practice',
          'routine': 'beginner',
          'frequency': 'Daily',
        },
        {
          'week': 3,
          'title': 'Progress Week',
          'description': 'Increase to intermediate routines',
          'routine': 'intermediate',
          'frequency': 'Daily',
        },
        {
          'week': 4,
          'title': 'Mastery Week',
          'description': 'Challenge yourself with advanced routines',
          'routine': 'advanced',
          'frequency': 'Daily',
        },
      ],
    };
  }
}
