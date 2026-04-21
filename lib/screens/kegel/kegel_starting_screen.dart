import 'dart:async';
import 'package:flutter/services.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/services/kegel_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:velmora/services/vibration_service.dart';

class KegelStartingScreen extends StatefulWidget {
  final String routineType;
  final int durationMinutes;
  final int sets;

  const KegelStartingScreen({
    super.key,
    this.routineType = "Beginner Routine",
    this.durationMinutes = 3,
    this.sets = 2,
  });

  @override
  State<KegelStartingScreen> createState() => _KegelStartingScreenState();
}

class _KegelStartingScreenState extends State<KegelStartingScreen> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _currentSet = 1;
  int _currentPhase =
      1; // 1: Hold & Squeeze, 2: Rest & Relax, 3: Rest Between Sets, 4: Pulses
  bool _isPlaying = false;
  bool _isCompleted = false;
  bool _isReadyForNextLevel = false;

  // Timing configuration
  int _phaseSeconds = 0;
  int _cycleCount = 0; // Track current repetition
  int _currentStepIndex = 0;
  bool _initialized = false;

  // Exercise Structures
  List<Map<String, dynamic>> _currentSteps = [];

  final KegelService _kegelService = KegelService();

  @override
  void initState() {
    super.initState();
    // NOTE: Do NOT call _initializeExerciseStructure() here.
    // AppLocalizations.of(context) requires inherited widgets which are
    // not available yet in initState. Use didChangeDependencies() instead.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initializeExerciseStructure();
      _loadInitialStep();
    }
  }

  void _initializeExerciseStructure() {
    final l10n = AppLocalizations.of(context);
    if (widget.routineType.toLowerCase().contains('beginner')) {
      _currentSteps = [
        {'name': l10n.beginnerRoutine, 'contract': 3, 'relax': 3, 'reps': 11},
        {'name': l10n.beginnerRoutine, 'contract': 5, 'relax': 3, 'reps': 1},
      ];
    } else if (widget.routineType.toLowerCase().contains('intermediate')) {
      _currentSteps = [
        {'name': l10n.slowContractions, 'contract': 5, 'relax': 5, 'reps': 10},
        {'name': l10n.quickPulses, 'contract': 1, 'relax': 1, 'reps': 20},
        {'name': l10n.enduranceHold, 'contract': 15, 'relax': 10, 'reps': 3},
      ];
    } else if (widget.routineType.toLowerCase().contains('advanced')) {
      _currentSteps = [
        {
          'name': l10n.progressiveHolds,
          'contract': [5, 10, 15, 20],
          'relax': [5, 10, 15, 20],
          'reps': 4,
          'isSequence': true,
        },
        {
          'name': l10n.pyramidTraining,
          'contract': [3, 5, 7, 10, 7, 5, 3],
          'relax': [3, 5, 7, 10, 7, 5, 3],
          'reps': 7,
          'isSequence': true,
        },
        {'name': l10n.explosivePulses, 'contract': 1, 'relax': 1, 'reps': 30},
        {
          'name': l10n.mixedControlSet,
          'contract': 10,
          'relax': 10,
          'reps': 3,
          'hasPulses': true,
          'pulseCount': 10,
        },
      ];
    } else {
      _currentSteps = [
        {'name': l10n.basicRoutine, 'contract': 3, 'relax': 3, 'reps': 10},
      ];
    }
  }

  void _loadInitialStep() {
    _currentStepIndex = 0;
    _cycleCount = 0;
    _currentPhase = 1;
    _updatePhaseSeconds();
  }

  void _updatePhaseSeconds() {
    final step = _currentSteps[_currentStepIndex];
    if (_currentPhase == 1) {
      // Contract
      if (step['isSequence'] == true) {
        _phaseSeconds = (step['contract'] as List)[_cycleCount];
      } else {
        _phaseSeconds = step['contract'];
      }
    } else if (_currentPhase == 2) {
      // Relax
      if (step['isSequence'] == true) {
        _phaseSeconds = (step['relax'] as List)[_cycleCount];
      } else {
        _phaseSeconds = step['relax'];
      }
    } else if (_currentPhase == 4) {
      // Pulses (Advanced Mixed Set)
      _phaseSeconds =
          (step['pulseCount'] ?? 10) *
          2; // Pulse is 1s contract + 1s relax (implied)
    } else if (_currentPhase == 3) {
      // Rest between sets
      _phaseSeconds = 30; // Standard rest
    }
  }

  int get _totalDotsInCurrentStep {
    return _currentSteps[_currentStepIndex]['reps'];
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        _elapsedSeconds++;
        _phaseSeconds--;

        if (_currentPhase == 1) {
          HapticFeedback.lightImpact();
        }

        if (_phaseSeconds <= 0) {
          _togglePhase();
        }

        final totalSeconds = widget.durationMinutes * 60;
        if (_elapsedSeconds >= totalSeconds) {
          _completeExercise();
        }
      });
    });
  }

  void _togglePhase() {
    final step = _currentSteps[_currentStepIndex];

    if (_currentPhase == 1) {
      // From Hold & Squeeze to Next Phase
      if (step['hasPulses'] == true) {
        _currentPhase = 4; // Advanced pulses
      } else {
        _currentPhase = 2; // Normal relax
      }
    } else if (_currentPhase == 4) {
      // From Pulses to Relax
      _currentPhase = 2;
    } else if (_currentPhase == 2) {
      // Finished a repetition
      _cycleCount++;

      if (_cycleCount >= step['reps']) {
        // Move to next step or next set
        _cycleCount = 0;
        if (_currentStepIndex < _currentSteps.length - 1) {
          _currentStepIndex++;
          _currentPhase = 1;
        } else {
          // Finished all steps in the current set
          if (_currentSet < widget.sets) {
            _currentSet++;
            _currentStepIndex = 0;
            _currentPhase = 3; // Rest between sets
            _phaseSeconds = 30; // Standard rest
            return;
          } else {
            // All sets done
            _completeExercise();
            return;
          }
        }
      } else {
        // Next rep in the same step
        _currentPhase = 1;
      }
    } else if (_currentPhase == 3) {
      // Rest between sets is over
      _currentPhase = 1;
      _currentStepIndex = 0;
      _cycleCount = 0;
    }

    _updatePhaseSeconds();
    VibrationService.vibration();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        VibrationService.doubleVibration();
        _startTimer();
      } else {
        _timer?.cancel();
      }
    });
  }

  void _completeExercise() async {
    _timer?.cancel();
    setState(() {
      _isCompleted = true;
      _isPlaying = false;
    });
    VibrationService.longVibration();

    await _kegelService.saveSession(
      routineType: widget.routineType,
      durationMinutes: widget.durationMinutes,
      setsCompleted: _currentSet > widget.sets ? widget.sets : _currentSet,
    );

    final data = await _kegelService.getKegelData();
    if (mounted) {
      setState(() {
        int currentStreak =
            data?['currentStreak'] ??
            0; // Assuming currentStreak tracks daily practice
        if (widget.routineType.toLowerCase().contains('beginner') &&
            currentStreak >= 3) {
          _isReadyForNextLevel = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Returns a localized display title for the routine, regardless of the
  /// language-neutral [widget.routineType] ID passed from the parent.
  String _getLocalizedRoutineTitle(AppLocalizations l10n) {
    final id = widget.routineType.toLowerCase();
    if (id.contains('intermediate')) return l10n.intermediateLevelTitle;
    if (id.contains('advanced')) return l10n.advancedLevelTitle;
    return l10n.beginnerLevelTitle; // default / 'beginner'
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isCompleted) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        body: Stack(
          children: [
            // Pink/Magenta Gradient Header
            Container(
              width: double.infinity,
              height: 300.h,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF5B88), Color(0xFFFF5277)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 60.h),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                    child: Text(
                      _getLocalizedRoutineTitle(l10n),
                      style: TextStyle(
                        fontSize: 20.fSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "${l10n.set} $_currentSet ${l10n.ofLabel} ${widget.sets}",
                    style: TextStyle(
                      fontSize: 16.fSize,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // White Card
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 25.w),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.adaptSize),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Checkmark Circle
                    Container(
                      width: 80.adaptSize,
                      height: 80.adaptSize,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5B88), Color(0xFFFF5277)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5277).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 50.adaptSize,
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Builder(
                      builder: (context) {
                        if (widget.routineType.toLowerCase().contains(
                          'intermediate',
                        )) {
                          return Column(
                            children: [
                              Text(
                                AppLocalizations.of(context).greatWorkEmoji,
                                style: TextStyle(
                                  fontSize: 28.fSize,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F1F1F),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                AppLocalizations.of(
                                  context,
                                ).completedIntermediateBody,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 16.fSize,
                                  color: Colors.grey.shade600,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          );
                        } else if (widget.routineType.toLowerCase().contains(
                          'advanced',
                        )) {
                          return Column(
                            children: [
                              Text(
                                AppLocalizations.of(context).elitePerformance,
                                style: TextStyle(
                                  fontSize: 20.fSize,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F1F1F),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                AppLocalizations.of(
                                  context,
                                ).completedAdvancedBody,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 16.fSize,
                                  color: Colors.grey.shade600,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Beginner Level
                          return Column(
                            children: [
                              Text(
                                AppLocalizations.of(context).greatJobEmoji,
                                style: TextStyle(
                                  fontSize: 28.fSize,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F1F1F),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                AppLocalizations.of(
                                  context,
                                ).beginnerRoutineCompleteMsg(widget.sets),
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 16.fSize,
                                  color: Colors.grey.shade600,
                                  height: 1.5,
                                ),
                              ),
                              if (_isReadyForNextLevel)
                                Padding(
                                  padding: EdgeInsets.only(top: 16.h),
                                  child: Text(
                                    AppLocalizations.of(context).readyNextLevel,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16.fSize,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF9B3BFF),
                                    ),
                                  ), // Purple
                                ),
                            ],
                          );
                        }
                      },
                    ),
                    SizedBox(height: 20.h),
                    // Finish Button
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9B3BFF), // Purple
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.adaptSize),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.finish,
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
              ),
            ),
          ],
        ),
      );
    }

    final totalSeconds = widget.durationMinutes * 60;
    final progressVal = (_elapsedSeconds / totalSeconds).clamp(0.0, 1.0);

    Widget circleContent = Container(
      width: 200.adaptSize,
      height: 200.adaptSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _currentPhase == 1
              ? const Color(0xFF8B3DFF) // Purple for Hold & Squeeze
              : _currentPhase == 2
              ? const Color(0xFF13D187) // Green for Rest & Relax
              : const Color(0xFFFF9800), // Orange for Rest Between Sets
          width: 10.adaptSize,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$_phaseSeconds",
            style: TextStyle(
              fontSize: 64.fSize,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF111827),
            ),
          ),
          Text(
            AppLocalizations.of(context).secondsLabel,
            style: TextStyle(
              fontSize: 12.fSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );

    if (_isPlaying) {
      circleContent = circleContent
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scaleXY(
            begin: 0.9,
            end: 1.1,
            duration: 1.seconds,
            curve: Curves.easeInOut,
          );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Stack(
        children: [
          // Dynamic Background Color based on phase
          AnimatedContainer(
            height: 300.h,
            width: double.infinity,
            duration: const Duration(milliseconds: 300),
            color: _currentPhase == 2
                ? const Color(0xFF13D187) // Green for Rest & Relax
                : _currentPhase == 3
                ? const Color(0xFFFF9800) // Orange for Rest Between Sets
                : const Color(0xFF8B3DFF), // Purple for Hold & Squeeze
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 20.w, top: 10.h),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24.adaptSize,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    _getLocalizedRoutineTitle(l10n),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.fSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  l10n.setOfLabel(
                    _currentSet > widget.sets ? widget.sets : _currentSet,
                    widget.sets,
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.fSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 30.h),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      left: 20.w,
                      right: 20.w,
                      bottom: 40.h,
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.adaptSize),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          SizedBox(height: 30.h),
                          // Big Timer Circle
                          circleContent,
                          SizedBox(height: 30.h),
                          Text(
                            _currentPhase == 1
                                ? AppLocalizations.of(context).holdAndSqueeze
                                : _currentPhase == 2
                                ? AppLocalizations.of(context).restAndRelax
                                : _currentPhase == 4
                                ? AppLocalizations.of(context).pulses
                                : AppLocalizations.of(context).restBetweenSets,
                            style: TextStyle(
                              fontSize: 18.fSize,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            _currentSteps[_currentStepIndex]['name'],
                            style: TextStyle(
                              fontSize: 16.fSize,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          SizedBox(height: 15.h),
                          // Cycle Dots Indicator (dynamic based on routine)
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6.w,
                            runSpacing: 8.h,
                            children: List.generate(_totalDotsInCurrentStep, (
                              index,
                            ) {
                              bool isCompleted = index < _cycleCount;
                              bool isCurrent =
                                  index == _cycleCount &&
                                  (_currentPhase == 1 ||
                                      _currentPhase == 2 ||
                                      _currentPhase == 4);
                              return Container(
                                width: 10.adaptSize,
                                height: 10.adaptSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted
                                      ? const Color(
                                          0xFF8B3DFF,
                                        ) // Purple for completed
                                      : isCurrent
                                      ? (_currentPhase == 1 ||
                                                _currentPhase == 4)
                                            ? const Color(
                                                0xFF8B3DFF,
                                              ) // Purple for Hold & Squeeze
                                            : const Color(
                                                0xFF13D187,
                                              ) // Green for Rest & Relax
                                      : const Color(0xFFE5E7EB),
                                  border: isCurrent
                                      ? Border.all(
                                          color:
                                              (_currentPhase == 1 ||
                                                  _currentPhase == 4)
                                              ? const Color(
                                                  0xFF8B3DFF,
                                                ) // Purple border for Hold
                                              : const Color(
                                                  0xFF13D187,
                                                ), // Green border for Rest
                                          width: 2,
                                        )
                                      : null,
                                ),
                              );
                            }),
                          ),
                          SizedBox(height: 8.h),
                          // Text(
                          //   "Cycle ${_cycleCount + 1} of $_cyclesPerSet",
                          //   style: TextStyle(
                          //     fontSize: 12.fSize,
                          //     color: Colors.grey.shade600,
                          //   ),
                          // ),
                          SizedBox(height: 20.h),
                          // Resume/Pause Button
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: GestureDetector(
                              onTap: _togglePlayPause,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B3DFF),
                                  borderRadius: BorderRadius.circular(
                                    16.adaptSize,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow_outlined,
                                      color: Colors.white,
                                      size: 20.adaptSize,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      _isPlaying
                                          ? AppLocalizations.of(
                                              context,
                                            ).pauseLabel
                                          : AppLocalizations.of(
                                              context,
                                            ).resumeLabel,
                                      style: TextStyle(
                                        fontSize: 16.fSize,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          // Overall Progress Section
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.overallProgressLabel,
                                  style: TextStyle(
                                    fontSize: 13.fSize,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4B5563),
                                  ),
                                ),
                                Text(
                                  "${(progressVal * 100).toInt()}%",
                                  style: TextStyle(
                                    fontSize: 13.fSize,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.centerLeft,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 6.adaptSize,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5E7EB),
                                    borderRadius: BorderRadius.circular(
                                      3.adaptSize,
                                    ),
                                  ),
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final progressWidth =
                                        constraints.maxWidth * progressVal;
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        Container(
                                          width: progressWidth,
                                          height: 6.adaptSize,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF8B3DFF),
                                            borderRadius: BorderRadius.circular(
                                              3.adaptSize,
                                            ),
                                          ),
                                        ),
                                        if (progressWidth > 0)
                                          Positioned(
                                            left: progressWidth - 5.adaptSize,
                                            child: Container(
                                              width: 10.adaptSize,
                                              height: 10.adaptSize,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Color(0xFF8B3DFF),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 32.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
