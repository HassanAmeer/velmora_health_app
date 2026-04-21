import 'package:velmora/screens/settings/subscription_screen.dart';
import 'package:velmora/services/subscription_service.dart';
import 'package:velmora/services/user_service.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/screens/kegel/kegel_challenge_screen.dart';
import 'package:velmora/screens/kegel/kegel_starting_screen.dart';
import 'package:velmora/services/kegel_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velmora/widgets/skeletons/kegel_skeleton.dart';

class KegelScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const KegelScreen({super.key, this.onBackToHome});

  @override
  State<KegelScreen> createState() => _KegelScreenState();
}

class _KegelScreenState extends State<KegelScreen> {
  final KegelService _kegelService = KegelService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _kegelData;
  List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = true;
  bool _showChallengeBanner = true;

  @override
  void initState() {
    super.initState();
    _loadKegelData();
  }

  Future<void> _loadKegelData() async {
    try {
      final data = await _kegelService.getKegelData();
      final exercises = await _loadExercises();
      if (mounted) {
        setState(() {
          _kegelData = data;
          _exercises = exercises;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadExercises() async {
    try {
      // Load exercises from Firestore
      final exercisesSnapshot = await _firestore
          .collection('kegel_exercises')
          .get();

      List<Map<String, dynamic>> exercises = [];

      for (var doc in exercisesSnapshot.docs) {
        final data = doc.data();
        String localizedName = data['name'] ?? 'Exercise';
        if (doc.id == 'beginner') {
          localizedName = AppLocalizations.of(context).beginnerLevelTitle;
        } else if (doc.id == 'intermediate') {
          localizedName = AppLocalizations.of(context).intermediateLevelTitle;
        } else if (doc.id == 'advanced') {
          localizedName = AppLocalizations.of(context).advancedLevelTitle;
        }

        exercises.add({
          'id': doc.id,
          'name': localizedName,
          'duration': doc.id == 'beginner' ? 3 : (data['duration'] ?? 5),
          'sets': doc.id == 'beginner' ? 2 : (data['sets'] ?? 1),
          'isPremium': data['isPremium'] ?? false,
          'isActive': data['isActive'] ?? true,
        });
      }

      // If no exercises in Firestore, use defaults
      if (exercises.isEmpty) {
        exercises = _getDefaultExercises();
      }

      // Filter out inactive exercises
      exercises = exercises.where((e) => e['isActive'] == true).toList();

      return exercises;
    } catch (e) {
      // If Firestore fails, use defaults
      return _getDefaultExercises();
    }
  }

  List<Map<String, dynamic>> _getDefaultExercises() {
    return [
      {
        'id': 'beginner',
        'name': AppLocalizations.of(context).beginnerLevelTitle,
        'duration': 3, // ~2:30 min
        'sets': 2,
        'isPremium': false,
        'isActive': true,
      },
      {
        'id': 'intermediate',
        'name': AppLocalizations.of(context).intermediateLevelTitle,
        'duration': 4, // ~3:35 min
        'sets': 1,
        'isPremium': true,
        'isActive': true,
      },
      {
        'id': 'advanced',
        'name': AppLocalizations.of(context).advancedLevelTitle,
        'duration': 6, // ~5:30 min
        'sets': 1,
        'isPremium': true,
        'isActive': true,
      },
    ];
  }

  Future<void> _navigateToKegelStartingScreen(
    String routineType,
    int durationMinutes,
    int sets,
    bool isPremium,
  ) async {
    if (isPremium) {
      final hasAccess =
          await SubscriptionService().hasActiveSubscription() ||
          await UserService().isTrialActive();

      if (!hasAccess && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PremiumScreen()),
        );
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KegelStartingScreen(
          routineType: routineType,
          durationMinutes: durationMinutes,
          sets: sets,
        ),
      ),
    ).then((_) => _loadKegelData());
  }

  int get _weekStreak => _kegelData?['weekStreak'] ?? 0;
  int get _totalCompleted => _kegelData?['totalCompleted'] ?? 0;
  double get _dailyGoalPercent =>
      (_kegelData?['dailyGoalPercent'] ?? 0.0).toDouble();

  Color _getExerciseColor(String exerciseId) {
    switch (exerciseId) {
      case 'beginner':
        return const Color(0xFF4CAF50);
      case 'intermediate':
        return const Color(0xFF9B67FF);
      case 'advanced':
        return const Color(0xFFFF4D8D);
      default:
        return const Color(0xFF6B26FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: (_isLoading)
          ? const KegelScreenSkeleton()
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildHeader(context),
                      Positioned(
                        bottom: -190.h,
                        left: 20.w,
                        right: 20.w,
                        child: _buildProgressCard(),
                      ),
                    ],
                  ),
                  RefreshIndicator(
                    onRefresh: _loadKegelData,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 220.h),
                          if (_showChallengeBanner) _buildChallengePromoCard(),
                          SizedBox(height: 24.h),
                          Text(
                            AppLocalizations.of(context).exerciseRoutines,
                            style: TextStyle(
                              fontSize: 18.fSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          if (_exercises.isEmpty)
                            Center(
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).noExercisesAvailable,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            ..._exercises.map(
                              (exercise) => Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: _buildRoutineCard(
                                  title: exercise['name'],
                                  subtitle: exercise['id'] == 'beginner'
                                      ? AppLocalizations.of(
                                          context,
                                        ).beginnerSubtitle
                                      : exercise['id'] == 'intermediate'
                                      ? AppLocalizations.of(
                                          context,
                                        ).intermediateSubtitle
                                      : AppLocalizations.of(
                                          context,
                                        ).advancedSubtitle,
                                  iconBg: _getExerciseColor(exercise['id']),
                                  playBtnColor: const Color(0xFF6B26FF),
                                  isPremium: exercise['isPremium'] ?? false,
                                  onTap: () => _showRoutineDetails(exercise),
                                ),
                              ),
                            ),
                          SizedBox(height: 24.h),
                          _buildPremiumPromoCard(),
                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180.h,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9B67FF), Color(0xFF6B26FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 50.h, 20.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (widget.onBackToHome != null) {
                    widget.onBackToHome!();
                    return;
                  }
                  Navigator.pop(context);
                },
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24.adaptSize,
                ),
              ),
              SizedBox(width: 12.w),
              Icon(Icons.bolt, color: Colors.white, size: 28.adaptSize),
              SizedBox(width: 8.w),
              Text(
                AppLocalizations.of(context).kegel,
                style: TextStyle(
                  fontSize: 24.fSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context).intimateWellnessJourney,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14.fSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
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
            AppLocalizations.of(context).yourProgress,
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.adaptSize),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F0),
                    borderRadius: BorderRadius.circular(12.adaptSize),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: Colors.orange,
                            size: 20.adaptSize,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            AppLocalizations.of(context).weekStreak,
                            style: TextStyle(
                              fontSize: 12.fSize,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "$_weekStreak",
                        style: TextStyle(
                          fontSize: 24.fSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.adaptSize),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FFF4),
                    borderRadius: BorderRadius.circular(12.adaptSize),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 20.adaptSize,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            AppLocalizations.of(context).completedLabel,
                            style: TextStyle(
                              fontSize: 12.fSize,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "$_totalCompleted",
                        style: TextStyle(
                          fontSize: 24.fSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).dailyGoal,
                style: TextStyle(fontSize: 12.fSize, color: Colors.black54),
              ),
              Text(
                "${_dailyGoalPercent.toInt()}%",
                style: TextStyle(fontSize: 12.fSize, color: Colors.black54),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_dailyGoalPercent / 100).clamp(0.0, 1.0),
              minHeight: 6.h,
              backgroundColor: const Color(0xFF9B67FF).withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF9B67FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard({
    required String title,
    required String subtitle,
    required Color iconBg,
    required Color playBtnColor,
    required VoidCallback onTap,
    bool isPremium = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12.adaptSize),
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                color: Colors.white,
                size: 28.adaptSize,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16.fSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (isPremium) ...[
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.workspace_premium,
                          color: const Color(0xFFFFD700),
                          size: 20.adaptSize,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13.fSize, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: playBtnColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 20.adaptSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoutineDetails(Map<String, dynamic> exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: EdgeInsets.all(24.adaptSize),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                exercise['name'],
                style: TextStyle(
                  fontSize: 22.fSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildExerciseDescription(exercise['id']),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToKegelStartingScreen(
                      exercise['id'], // always 'beginner'/'intermediate'/'advanced'
                      exercise['duration'],
                      exercise['sets'],
                      exercise['isPremium'] ?? false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B26FF),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.adaptSize),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).startSession,
                    style: TextStyle(
                      fontSize: 18.fSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExerciseDescription(String id) {
    if (id == 'beginner') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).beginnerDesc, style: _descStyle),
          SizedBox(height: 16.h),
          Text(
            AppLocalizations.of(context).exerciseInstructions,
            style: _subHeaderStyle,
          ),
          SizedBox(height: 8.h),
          _buildBulletPoint(AppLocalizations.of(context).beginnerInst1),
          _buildBulletPoint(AppLocalizations.of(context).beginnerInst2),
          _buildBulletPoint(AppLocalizations.of(context).beginnerInst3),
          _buildBulletPoint(AppLocalizations.of(context).beginnerInst4),
          _buildBulletPoint(AppLocalizations.of(context).beginnerInst5),
          SizedBox(height: 16.h),
          Text(AppLocalizations.of(context).tipsColon, style: _subHeaderStyle),
          SizedBox(height: 8.h),
          _buildBulletPoint(AppLocalizations.of(context).beginnerTip1),
          _buildBulletPoint(AppLocalizations.of(context).beginnerTip2),
          _buildBulletPoint(AppLocalizations.of(context).beginnerTip3),
          _buildBulletPoint(AppLocalizations.of(context).beginnerTip4),
          SizedBox(height: 16.h),
          Text(AppLocalizations.of(context).goal, style: _subHeaderStyle),
          SizedBox(height: 8.h),
          Text(AppLocalizations.of(context).beginnerGoal, style: _descStyle),
        ],
      );
    } else if (id == 'intermediate') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).intermediateDesc,
            style: _descStyle,
          ),
          SizedBox(height: 16.h),
          Text(
            AppLocalizations.of(context).exerciseStructure,
            style: _subHeaderStyle,
          ),
          SizedBox(height: 8.h),
          Text(AppLocalizations.of(context).intStruct1, style: _boldDescStyle),
          _buildBulletPoint(AppLocalizations.of(context).intInst11),
          _buildBulletPoint(AppLocalizations.of(context).intInst12),
          _buildBulletPoint(AppLocalizations.of(context).intInst13),
          SizedBox(height: 8.h),
          Text(AppLocalizations.of(context).intStruct2, style: _boldDescStyle),
          _buildBulletPoint(AppLocalizations.of(context).intInst21),
          _buildBulletPoint(AppLocalizations.of(context).intInst22),
          _buildBulletPoint(AppLocalizations.of(context).intInst23),
          SizedBox(height: 8.h),
          Text(AppLocalizations.of(context).intStruct3, style: _boldDescStyle),
          _buildBulletPoint(AppLocalizations.of(context).intInst31),
          _buildBulletPoint(AppLocalizations.of(context).intInst32),
          _buildBulletPoint(AppLocalizations.of(context).intInst33),
          SizedBox(height: 16.h),
          Text(AppLocalizations.of(context).tipsColon, style: _subHeaderStyle),
          SizedBox(height: 8.h),
          _buildBulletPoint(AppLocalizations.of(context).intTip1),
          _buildBulletPoint(AppLocalizations.of(context).intTip2),
          _buildBulletPoint(AppLocalizations.of(context).intTip3),
          SizedBox(height: 16.h),
          Text(AppLocalizations.of(context).goal, style: _subHeaderStyle),
          SizedBox(height: 8.h),
          Text(AppLocalizations.of(context).intGoal, style: _descStyle),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).advancedDesc, style: _descStyle),
          SizedBox(height: 16.h),
          Text(
            AppLocalizations.of(context).exerciseStructure,
            style: _subHeaderStyle,
          ),
          SizedBox(height: 8.h),
          Text(AppLocalizations.of(context).advStruct1, style: _boldDescStyle),
          _buildBulletPoint(AppLocalizations.of(context).advInst11),
          _buildBulletPoint(AppLocalizations.of(context).advInst12),
          _buildBulletPoint(AppLocalizations.of(context).advInst13),
          _buildBulletPoint(AppLocalizations.of(context).advInst14),
          SizedBox(height: 8.h),
          Text(AppLocalizations.of(context).advStruct2, style: _boldDescStyle),
          _buildBulletPoint(AppLocalizations.of(context).advInst21),
          _buildBulletPoint(AppLocalizations.of(context).advInst22),
          _buildBulletPoint(AppLocalizations.of(context).advInst23),
          _buildBulletPoint(AppLocalizations.of(context).advInst24),
          _buildBulletPoint(AppLocalizations.of(context).advInst25),
          _buildBulletPoint(AppLocalizations.of(context).advInst26),
          SizedBox(height: 8.h),
          Text(AppLocalizations.of(context).advStruct3, style: _boldDescStyle),
          _buildBulletPoint(AppLocalizations.of(context).advInst31),
          _buildBulletPoint(AppLocalizations.of(context).advInst32),
          _buildBulletPoint(AppLocalizations.of(context).advInst33),
          SizedBox(height: 8.h),
          Text(AppLocalizations.of(context).advStruct4, style: _boldDescStyle),
          _buildBulletPoint(AppLocalizations.of(context).advInst41),
          _buildBulletPoint(AppLocalizations.of(context).advInst42),
          _buildBulletPoint(AppLocalizations.of(context).intInst32),
          _buildBulletPoint(AppLocalizations.of(context).intInst33),
          SizedBox(height: 16.h),
          Text(AppLocalizations.of(context).tipsColon, style: _subHeaderStyle),
          SizedBox(height: 8.h),
          _buildBulletPoint(AppLocalizations.of(context).advTip1),
          _buildBulletPoint(AppLocalizations.of(context).advTip2),
          _buildBulletPoint(AppLocalizations.of(context).advTip3),
          SizedBox(height: 16.h),
          Text(AppLocalizations.of(context).goal, style: _subHeaderStyle),
          SizedBox(height: 8.h),
          Text(AppLocalizations.of(context).advGoal, style: _descStyle),
        ],
      );
    }
  }

  TextStyle get _subHeaderStyle => TextStyle(
    fontSize: 18.fSize,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  TextStyle get _descStyle =>
      TextStyle(fontSize: 14.fSize, color: Colors.black87, height: 1.5);
  TextStyle get _boldDescStyle => TextStyle(
    fontSize: 14.fSize,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
    height: 1.5,
  );

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, left: 8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: TextStyle(
              fontSize: 14.fSize,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(child: Text(text, style: _descStyle)),
        ],
      ),
    );
  }

  Widget _buildPremiumPromoCard() {
    return FutureBuilder<bool>(
      future: _checkIfPremium(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: EdgeInsets.all(20.adaptSize),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E2E3E), Color(0xFF1E1E2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.adaptSize),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: const Color(0xFFFFD700),
                    size: 28.adaptSize,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    AppLocalizations.of(context).unlockAdvancedTraining,
                    style: TextStyle(
                      fontSize: 18.fSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                AppLocalizations.of(context).premiumKegelDesc,
                style: TextStyle(
                  fontSize: 13.fSize,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16.h),
              _buildPremiumFeature(
                AppLocalizations.of(context).premiumKegelFeat1,
              ),
              _buildPremiumFeature(
                AppLocalizations.of(context).premiumKegelFeat2,
              ),
              _buildPremiumFeature(
                AppLocalizations.of(context).premiumKegelFeat3,
              ),
              _buildPremiumFeature(
                AppLocalizations.of(context).premiumKegelFeat4,
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PremiumScreen(),
                      ),
                    ).then((_) => _loadKegelData());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black87,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.adaptSize),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).startUpgrade,
                    style: TextStyle(
                      fontSize: 16.fSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _checkIfPremium() async {
    return await SubscriptionService().hasActiveSubscription() ||
        await UserService().isTrialActive();
  }

  Widget _buildPremiumFeature(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: const Color(0xFFFFD700),
            size: 18.adaptSize,
          ),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(color: Colors.white, fontSize: 13.fSize),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengePromoCard() {
    final l10n = AppLocalizations.of(context);
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const KegelChallengeScreen(),
              ),
            ).then((_) => _loadKegelData());
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.adaptSize),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.adaptSize),
              gradient: const LinearGradient(
                colors: [Color(0xFF6B26FF), Color(0xFF9B67FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B26FF).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.thirtyDaysLabel,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.fSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 7.h),
                      Text(
                        l10n.kegelChallenge,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.fSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        l10n.kegelChallengeSubtitle,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.fSize,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Text(
                            l10n.viewChallenge,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.fSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80.adaptSize,
                      height: 80.adaptSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 40.adaptSize,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 5.h,
          right: 5.w,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showChallengeBanner = false;
              });
            },
            child: Container(
              padding: EdgeInsets.all(4.adaptSize),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.white, size: 18.adaptSize),
            ),
          ),
        ),
      ],
    );
  }
}
