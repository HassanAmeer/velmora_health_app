import 'package:velmora/constants/app_colors.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/services/kegel_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/widgets/skeletons/kegel_challenge_skeleton.dart';
import 'package:flutter/material.dart';

class KegelChallengeScreen extends StatefulWidget {
  const KegelChallengeScreen({super.key});

  @override
  State<KegelChallengeScreen> createState() => _KegelChallengeScreenState();
}

class _KegelChallengeScreenState extends State<KegelChallengeScreen> {
  final KegelService _kegelService = KegelService();
  Map<String, dynamic>? _kegelData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKegelData();
  }

  Future<void> _loadKegelData() async {
    try {
      final data = await _kegelService.getKegelData();
      if (mounted) {
        setState(() {
          _kegelData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Returns the localized week data list (replacing the service's English strings).
  List<Map<String, dynamic>> _getLocalizedWeeks(AppLocalizations l10n) {
    return [
      {
        'week': 1,
        'title': l10n.week1Title,
        'description': l10n.week1Desc,
        'routine': 'beginner',
      },
      {
        'week': 2,
        'title': l10n.week2Title,
        'description': l10n.week2Desc,
        'routine': 'beginner',
      },
      {
        'week': 3,
        'title': l10n.week3Title,
        'description': l10n.week3Desc,
        'routine': 'intermediate',
      },
      {
        'week': 4,
        'title': l10n.week4Title,
        'description': l10n.week4Desc,
        'routine': 'advanced',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final completedDates =
        (_kegelData?['completedDates'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: AppColors.brandPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.kegelChallenge,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (_kegelData?['planProgress'] != null &&
              _kegelData!['planProgress'] > 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _showResetConfirmation,
              tooltip: l10n.resetChallengeLabel,
            ),
        ],
      ),
      body: _isLoading
          ? const KegelChallengeSkeleton()
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.adaptSize),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(l10n),
                  SizedBox(height: 24.h),
                  Text(
                    l10n.kegelPlan,
                    style: TextStyle(
                      fontSize: 18.fSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildProgressGrid(completedDates),
                  SizedBox(height: 24.h),
                  if ((_kegelData?['planProgress'] ?? 0) >= 30)
                    _buildCompletionCard(l10n)
                  else
                    _buildWeekCards(l10n, _getLocalizedWeeks(l10n)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(AppLocalizations l10n) {
    final progress = _kegelData?['planProgress'] ?? 0;
    final percent = (progress / 30).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.challengePlanTitle,
                      style: TextStyle(
                        fontSize: 18.fSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandPurple,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      l10n.percentComplete.replaceAll(
                        '{percent}',
                        '${(percent * 100).toInt()}',
                      ),
                      style: TextStyle(
                        fontSize: 14.fSize,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(12.adaptSize),
                decoration: BoxDecoration(
                  color: AppColors.brandPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.trending_up,
                  color: AppColors.brandPurple,
                  size: 24.adaptSize,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10.h,
              backgroundColor: AppColors.brandPurple.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.brandPurple,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            l10n.daysCompletedOutOfTotal
                .replaceAll('{done}', '$progress')
                .replaceAll('{total}', '30'),
            style: TextStyle(
              fontSize: 13.fSize,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressGrid(List<dynamic> completedDates) {
    return Container(
      padding: EdgeInsets.all(16.adaptSize),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.adaptSize),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 10.h,
        ),
        itemCount: 30,
        itemBuilder: (context, index) {
          final dayNum = index + 1;
          final progress = _kegelData?['planProgress'] ?? 0;
          final isCompleted = dayNum <= progress;

          return Container(
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.brandPurple : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10.adaptSize),
              border: Border.all(
                color: isCompleted
                    ? AppColors.brandPurple
                    : Colors.grey.shade300,
              ),
            ),
            alignment: Alignment.center,
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '$dayNum',
                    style: TextStyle(
                      fontSize: 12.fSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildWeekCards(
    AppLocalizations l10n,
    List<Map<String, dynamic>> weeks,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: weeks.map<Widget>((week) {
        final routineLabel = _getRoutineLabel(l10n, week['routine'] as String);
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.adaptSize),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.adaptSize),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                width: 48.adaptSize,
                height: 48.adaptSize,
                decoration: BoxDecoration(
                  color: AppColors.brandPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.adaptSize),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${l10n.weekLabel}${week['week']}',
                  style: TextStyle(
                    color: AppColors.brandPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.fSize,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      week['title'] as String,
                      style: TextStyle(
                        fontSize: 15.fSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      week['description'] as String,
                      style: TextStyle(
                        fontSize: 12.fSize,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color:
                      _getRoutineColor(week['routine'] as String).withOpacity(
                        0.1,
                      ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  routineLabel,
                  style: TextStyle(
                    fontSize: 10.fSize,
                    fontWeight: FontWeight.bold,
                    color: _getRoutineColor(week['routine'] as String),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getRoutineLabel(AppLocalizations l10n, String routine) {
    switch (routine) {
      case 'beginner':
        return l10n.routineBeginner;
      case 'intermediate':
        return l10n.routineIntermediate;
      case 'advanced':
        return l10n.routineAdvanced;
      default:
        return routine.toUpperCase();
    }
  }

  Color _getRoutineColor(String routine) {
    switch (routine) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return AppColors.brandPurple;
    }
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).kegelChallenge),
        content: Text(
          AppLocalizations.of(context).resetChallengeProgressConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              await _kegelService.resetChallenge();
              await _loadKegelData();
            },
            child: Text(
              AppLocalizations.of(context).resetLabel,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.adaptSize),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.adaptSize),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 64),
          SizedBox(height: 16.h),
          Text(
            l10n.challengeCompletedLabel,
            style: TextStyle(
              fontSize: 22.fSize,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.challengeCompletionMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.fSize, color: Colors.grey.shade700),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: _showResetConfirmation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.adaptSize),
              ),
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
            ),
            child: Text(
              l10n.restartChallenge,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
