import 'package:velmora/constants/app_colors.dart';
import 'package:velmora/services/kegel_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/widgets/skeletons/kegel_achievements_skeleton.dart';
import 'package:flutter/material.dart';

class KegelAchievementsScreen extends StatefulWidget {
  const KegelAchievementsScreen({super.key});

  @override
  State<KegelAchievementsScreen> createState() =>
      _KegelAchievementsScreenState();
}

class _KegelAchievementsScreenState extends State<KegelAchievementsScreen> {
  final KegelService _kegelService = KegelService();

  Map<String, dynamic>? _kegelData;
  List<Map<String, dynamic>> _weeklyProgress = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _kegelService.getKegelData();
      final weeklyProgress = await _kegelService.getWeeklyProgress();

      if (mounted) {
        setState(() {
          _kegelData = data;
          _weeklyProgress = weeklyProgress;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> get _unlockedAchievements =>
      List<String>.from(_kegelData?['achievements'] ?? []);

  int get _totalMinutes => _kegelData?['totalMinutes'] ?? 0;
  int get _longestStreak => _kegelData?['longestStreak'] ?? 0;
  int get _totalCompleted => _kegelData?['totalCompleted'] ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: AppColors.brandPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Achievements & Progress',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const KegelAchievementsSkeleton()
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCards(),
                  SizedBox(height: 24.h),
                  _buildWeeklyChart(),
                  SizedBox(height: 24.h),
                  _buildAchievementsSection(),
                  SizedBox(height: 24.h),
                  _build30DayPlan(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Minutes',
            '$_totalMinutes',
            Icons.timer_outlined,
            Colors.blue,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            'Longest Streak',
            '$_longestStreak days',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.adaptSize),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.adaptSize),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24.adaptSize),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.fSize,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(fontSize: 12.fSize, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      padding: EdgeInsets.all(20.adaptSize),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.adaptSize),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: TextStyle(
              fontSize: 18.fSize,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _weeklyProgress.map((day) {
              final completed = day['completed'] as bool;
              return Column(
                children: [
                  Container(
                    width: 32.w,
                    height: completed ? 60.h : 30.h,
                    decoration: BoxDecoration(
                      color: completed
                          ? AppColors.brandPurple
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8.adaptSize),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    day['day'],
                    style: TextStyle(
                      fontSize: 11.fSize,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final allAchievements = _kegelService.getAllAchievements();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: TextStyle(
            fontSize: 18.fSize,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),
        ...allAchievements.map((achievement) {
          final achievementId = allAchievements.indexOf(achievement);
          final achievementKey = [
            'first_exercise',
            'week_warrior',
            'month_master',
            'century_club',
            'time_champion',
            'streak_legend',
          ][achievementId];

          final isUnlocked = _unlockedAchievements.contains(achievementKey);

          return _buildAchievementCard(
            achievement['title'],
            achievement['description'],
            achievement['icon'],
            Color(achievement['color']),
            isUnlocked,
          );
        }),
      ],
    );
  }

  Widget _buildAchievementCard(
    String title,
    String description,
    String icon,
    Color color,
    bool unlocked,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.adaptSize),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16.adaptSize),
        border: Border.all(
          color: unlocked ? color.withOpacity(0.3) : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50.adaptSize,
            height: 50.adaptSize,
            decoration: BoxDecoration(
              color: unlocked ? color.withOpacity(0.1) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12.adaptSize),
            ),
            child: Center(
              child: Text(icon, style: TextStyle(fontSize: 24.fSize)),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.fSize,
                    fontWeight: FontWeight.bold,
                    color: unlocked
                        ? AppColors.textPrimary
                        : Colors.grey.shade500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.fSize,
                    color: unlocked
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            Icon(Icons.check_circle, color: color, size: 24.adaptSize)
          else
            Icon(
              Icons.lock_outline,
              color: Colors.grey.shade400,
              size: 24.adaptSize,
            ),
        ],
      ),
    );
  }

  Widget _build30DayPlan() {
    final plan = _kegelService.get30DayPlan();
    final progress = _kegelData?['planProgress'] ?? 0;
    final progressPercent = (progress / 30 * 100).clamp(0, 100);

    return Container(
      padding: EdgeInsets.all(20.adaptSize),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.adaptSize),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 24),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  plan['title'],
                  style: TextStyle(
                    fontSize: 18.fSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            plan['description'],
            style: TextStyle(fontSize: 13.fSize, color: Colors.white70),
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress: $progress / 30 days',
                style: TextStyle(
                  fontSize: 14.fSize,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${progressPercent.toInt()}%',
                style: TextStyle(
                  fontSize: 14.fSize,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              minHeight: 8.h,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(height: 20.h),
          ...List.generate(4, (index) {
            final week = (plan['weeks'] as List)[index];
            return _buildWeekCard(
              week['week'],
              week['title'],
              week['description'],
              week['routine'],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeekCard(
    int week,
    String title,
    String description,
    String routine,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.adaptSize),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.adaptSize),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.adaptSize),
                ),
                child: Text(
                  'Week $week',
                  style: TextStyle(
                    fontSize: 11.fSize,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.fSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style: TextStyle(fontSize: 12.fSize, color: Colors.white70),
          ),
          SizedBox(height: 4.h),
          Text(
            'Routine: ${routine.toUpperCase()}',
            style: TextStyle(
              fontSize: 11.fSize,
              color: Colors.white60,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
