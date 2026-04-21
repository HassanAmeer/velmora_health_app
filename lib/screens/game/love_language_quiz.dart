import 'package:flutter/material.dart';
import 'package:velmora/services/game_service.dart';
import 'package:velmora/services/game_questions_service.dart';
import 'package:velmora/services/error_cache_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velmora/widgets/skeletons/game_skeleton.dart';
import 'package:velmora/widgets/game_progress_indicator.dart';
import 'package:velmora/models/game_question.dart';
import 'package:velmora/services/vibration_service.dart';

class LoveLanguageQuizScreen extends StatefulWidget {
  const LoveLanguageQuizScreen({super.key});

  @override
  State<LoveLanguageQuizScreen> createState() => _LoveLanguageQuizScreenState();
}

class _LoveLanguageQuizScreenState extends State<LoveLanguageQuizScreen> {
  final GameService _gameService = GameService();
  final GameQuestionsService _questionsService = GameQuestionsService();
  final TextEditingController _player1Controller = TextEditingController();
  final TextEditingController _player2Controller = TextEditingController();

  List<GameQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  String? _sessionId;
  bool _isLoading = true;
  bool _gameCompleted = false;
  bool _isPlayer1Turn = true;

  // Player names
  String _player1Name = 'Player 1';
  String _player2Name = 'Player 2';
  bool _namesSet = false;

  // Love language scores for both players
  final Map<String, int> _player1Scores = {
    'words_of_affirmation': 0,
    'quality_time': 0,
    'receiving_gifts': 0,
    'acts_of_service': 0,
    'physical_touch': 0,
  };

  final Map<String, int> _player2Scores = {
    'words_of_affirmation': 0,
    'quality_time': 0,
    'receiving_gifts': 0,
    'acts_of_service': 0,
    'physical_touch': 0,
  };

  String? _player1SelectedAnswer;
  String? _player2SelectedAnswer;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      print('🎮 [LoveLanguageQuiz] Starting initialization...');

      // Start game session
      print('🎮 [LoveLanguageQuiz] Starting game session...');
      try {
        _sessionId = await _gameService.startGameSessionById(
          'love_language_quiz',
        );
        print('🎮 [LoveLanguageQuiz] Session ID: $_sessionId');
      } catch (e) {
        print('❌ [LoveLanguageQuiz] Session start failed: $e');
        await ErrorCacheService().logGameError(
          gameId: 'love_language_quiz',
          phase: 'start_session',
          error: e.toString(),
          stack: StackTrace.current.toString(),
        );
        _sessionId = null; // Continue anyway
      }

      // Load questions using the new service
      print('🎮 [LoveLanguageQuiz] Loading questions...');
      final questions = await _questionsService.getQuestions(
        'love_language_quiz',
      );
      print('🎮 [LoveLanguageQuiz] Loaded ${questions.length} questions');

      // Validate questions have options
      if (questions.isEmpty) {
        throw Exception('No questions loaded for love_language_quiz');
      }

      // Check if questions have proper options
      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        if (q.options == null || q.options!.isEmpty) {
          print('⚠️ [LoveLanguageQuiz] Question $i has no options!');
        }
      }

      if (!mounted) return;

      setState(() {
        _questions = questions;
        _isLoading = false;
      });

      print('✅ [LoveLanguageQuiz] Initialization complete');
    } catch (e, stackTrace) {
      print('❌ [LoveLanguageQuiz] Initialization error: $e');
      print('❌ [LoveLanguageQuiz] Stack trace: $stackTrace');

      // Cache the error
      await ErrorCacheService().logGameError(
        gameId: 'love_language_quiz',
        phase: 'initialization',
        error: e.toString(),
        stack: stackTrace.toString(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).error}: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _setPlayerNames(AppLocalizations l10n) {
    if (_player1Controller.text.trim().isEmpty ||
        _player2Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseEnterNames)));
      return;
    }

    setState(() {
      _player1Name = _player1Controller.text.trim();
      _player2Name = _player2Controller.text.trim();
      _namesSet = true;
    });
    VibrationService.doubleVibration();
  }

  void _selectAnswer(String language) {
    setState(() {
      if (_isPlayer1Turn) {
        _player1SelectedAnswer = language;
      } else {
        _player2SelectedAnswer = language;
      }
    });
  }

  void _submitAnswer(AppLocalizations l10n) {
    final selectedAnswer = _isPlayer1Turn
        ? _player1SelectedAnswer
        : _player2SelectedAnswer;

    if (selectedAnswer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectAnswer)));
      return;
    }

    // Update score
    if (_isPlayer1Turn) {
      _player1Scores[selectedAnswer] =
          (_player1Scores[selectedAnswer] ?? 0) + 1;
    } else {
      _player2Scores[selectedAnswer] =
          (_player2Scores[selectedAnswer] ?? 0) + 1;
    }

    // Check if both players answered
    if (_player1SelectedAnswer != null && _player2SelectedAnswer != null) {
      // Both answered, move to next question
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _isPlayer1Turn = true;
          _player1SelectedAnswer = null;
          _player2SelectedAnswer = null;
        });
      } else {
        _completeGame(l10n);
      }
    } else {
      // Switch to other player
      setState(() {
        _isPlayer1Turn = !_isPlayer1Turn;
      });
    }
    VibrationService.vibration();
  }

  String _getPrimaryLoveLanguage(Map<String, int> scores) {
    String primary = '';
    int maxScore = 0;

    scores.forEach((language, score) {
      if (score > maxScore) {
        maxScore = score;
        primary = language;
      }
    });

    return primary;
  }

  String _getLoveLanguageTitle(String language, AppLocalizations l10n) {
    switch (language) {
      case 'words_of_affirmation':
        return l10n.wordsOfAffirmation;
      case 'quality_time':
        return l10n.qualityTime;
      case 'receiving_gifts':
        return l10n.receivingGifts;
      case 'acts_of_service':
        return l10n.actsOfService;
      case 'physical_touch':
        return l10n.physicalTouch;
      default:
        return '';
    }
  }

  String _getLoveLanguageDescription(String language, AppLocalizations l10n) {
    switch (language) {
      case 'words_of_affirmation':
        return l10n.loveLanguageWordsOfAffirmationDesc;
      case 'quality_time':
        return l10n.loveLanguageQualityTimeDesc;
      case 'receiving_gifts':
        return l10n.loveLanguageReceivingGiftsDesc;
      case 'acts_of_service':
        return l10n.loveLanguageActsOfServiceDesc;
      case 'physical_touch':
        return l10n.loveLanguagePhysicalTouchDesc;
      default:
        return '';
    }
  }

  int _calculateCompatibility() {
    final player1Primary = _getPrimaryLoveLanguage(_player1Scores);
    final player2Primary = _getPrimaryLoveLanguage(_player2Scores);

    // Calculate compatibility based on matching scores
    int matchingPoints = 0;
    int totalPoints = 0;

    _player1Scores.forEach((language, score1) {
      final score2 = _player2Scores[language] ?? 0;
      final minScore = score1 < score2 ? score1 : score2;
      matchingPoints += minScore;
      totalPoints += score1 + score2;
    });

    if (totalPoints == 0) return 0;

    // Bonus if primary languages match
    if (player1Primary == player2Primary) {
      matchingPoints += 2;
      totalPoints += 2;
    }

    return ((matchingPoints / totalPoints) * 100).round();
  }

  Future<void> _completeGame(AppLocalizations l10n) async {
    try {
      if (_sessionId != null) {
        await _gameService.completeGameSession(_sessionId!);

        // Save both players' results
        final player1Primary = _getPrimaryLoveLanguage(_player1Scores);
        final player2Primary = _getPrimaryLoveLanguage(_player2Scores);

        await FirebaseFirestore.instance
            .collection('user_game_progress')
            .doc(_gameService.currentUserId)
            .update({
              'loveLanguageResult': {
                'player1': {
                  'name': _player1Name,
                  'primaryLanguage': player1Primary,
                  'scores': _player1Scores,
                },
                'player2': {
                  'name': _player2Name,
                  'primaryLanguage': player2Primary,
                  'scores': _player2Scores,
                },
                'compatibility': _calculateCompatibility(),
                'completedAt': FieldValue.serverTimestamp(),
              },
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
      setState(() {
        _gameCompleted = true;
      });
      VibrationService.longVibration();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorCompletingQuiz)));
      }
    }
  }

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  Color get _primaryColor => const Color(0xFFB388FF);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: _primaryColor,
          title: Text(l10n.translate('love_language_quiz')),
          elevation: 0,
        ),
        body: const GameScreenSkeleton(),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: _primaryColor,
          title: Text(l10n.translate('love_language_quiz')),
          elevation: 0,
        ),
        body: Center(child: Text(l10n.errorLoadingQuiz)),
      );
    }

    // Player names input screen
    if (!_namesSet) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9FF),
        appBar: AppBar(
          backgroundColor: _primaryColor,
          title: Text(l10n.loveLanguageQuiz),
          elevation: 0,
        ),
        body: Padding(
          padding: EdgeInsets.all(24.adaptSize),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite, size: 80.adaptSize, color: _primaryColor),
              SizedBox(height: 24.h),
              Text(
                l10n.enterPlayerNames,
                style: TextStyle(
                  fontSize: 28.fSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2933),
                ),
              ),
              SizedBox(height: 40.h),
              TextField(
                controller: _player1Controller,
                decoration: InputDecoration(
                  labelText: l10n.player1Name,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.adaptSize),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _player2Controller,
                decoration: InputDecoration(
                  labelText: l10n.player2Name,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.adaptSize),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _setPlayerNames(l10n),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.adaptSize),
                    ),
                  ),
                  child: Text(
                    l10n.startQuiz,
                    style: TextStyle(
                      fontSize: 16.fSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Game completed screen
    if (_gameCompleted) {
      final player1Primary = _getPrimaryLoveLanguage(_player1Scores);
      final player2Primary = _getPrimaryLoveLanguage(_player2Scores);
      final compatibility = _calculateCompatibility();

      return Scaffold(
        backgroundColor: const Color(0xFFF9F9FF),
        appBar: AppBar(
          backgroundColor: _primaryColor,
          title: Text(l10n.loveLanguageQuiz),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.adaptSize),
            child: Column(
              children: [
                SizedBox(height: 20.h),
                Icon(Icons.favorite, size: 80.adaptSize, color: _primaryColor),
                SizedBox(height: 24.h),
                Text(
                  l10n.quizComplete,
                  style: TextStyle(
                    fontSize: 28.fSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2933),
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(20.adaptSize),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.adaptSize),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.compatibilityScore,
                        style: TextStyle(
                          fontSize: 18.fSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2933),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        '$compatibility%',
                        style: TextStyle(
                          fontSize: 48.fSize,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                _buildPlayerResult(
                  _player1Name,
                  player1Primary,
                  _player1Scores,
                  l10n,
                ),
                SizedBox(height: 24.h),
                _buildPlayerResult(
                  _player2Name,
                  player2Primary,
                  _player2Scores,
                  l10n,
                ),
                SizedBox(height: 40.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.adaptSize),
                      ),
                    ),
                    child: Text(
                      l10n.backToGames,
                      style: TextStyle(
                        fontSize: 16.fSize,
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
      );
    }

    // Game play screen
    final currentQuestion = _questions[_currentQuestionIndex];
    final options = currentQuestion.options ?? [];

    // CRITICAL FIX: Check if options is empty
    if (options.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: _primaryColor,
          title: Text(l10n.loveLanguageQuiz),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.adaptSize, color: Colors.red),
              SizedBox(height: 16.h),
              Text(
                'Question data is invalid',
                style: TextStyle(fontSize: 18.fSize),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.backToGames),
              ),
            ],
          ),
        ),
      );
    }

    final currentPlayer = _isPlayer1Turn ? _player1Name : _player2Name;
    final selectedAnswer = _isPlayer1Turn
        ? _player1SelectedAnswer
        : _player2SelectedAnswer;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: Text(l10n.loveLanguageQuiz),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          GameProgressIndicator(
            gameId: 'love_language_quiz',
            current: _currentQuestionIndex + 1,
            total: _questions.length,
            color: _primaryColor,
            label: '${l10n.questionOf} ${_currentQuestionIndex + 1} ${l10n.ofLabel} ${_questions.length}',
            trailingWidget: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? '${l10n.sTurn} $currentPlayer'
                    : '$currentPlayer ${l10n.sTurn}',
                style: TextStyle(
                  fontSize: 12.fSize,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ),
          ),

          // Question and options
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.adaptSize),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentQuestion.getLocalizedQuestion(
                      Localizations.localeOf(context).languageCode,
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22.fSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2933),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  ...options.map((option) {
                    final language = option.language ?? '';
                    final isSelected = selectedAnswer == language;

                    return GestureDetector(
                      onTap: () => _selectAnswer(language),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(16.adaptSize),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _primaryColor.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12.adaptSize),
                          border: Border.all(
                            color: isSelected
                                ? _primaryColor
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? _primaryColor
                                  : Colors.grey.shade400,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                option.getLocalizedText(
                                  Localizations.localeOf(context).languageCode,
                                ),
                                style: TextStyle(
                                  fontSize: 16.fSize,
                                  color: isSelected
                                      ? _primaryColor
                                      : Colors.grey.shade700,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Submit button
          Container(
            padding: EdgeInsets.all(24.adaptSize),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedAnswer != null
                    ? () => _submitAnswer(l10n)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.adaptSize),
                  ),
                ),
                child: Text(
                  l10n.submitAnswer,
                  style: TextStyle(
                    fontSize: 16.fSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerResult(
    String playerName,
    String primaryLanguage,
    Map<String, int> scores,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: EdgeInsets.all(24.adaptSize),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.adaptSize),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            playerName,
            style: TextStyle(
              fontSize: 20.fSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2933),
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(16.adaptSize),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.adaptSize),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLoveLanguageTitle(primaryLanguage, l10n),
                  style: TextStyle(
                    fontSize: 18.fSize,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _getLoveLanguageDescription(primaryLanguage, l10n),
                  style: TextStyle(
                    fontSize: 14.fSize,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          ...scores.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      _getLoveLanguageTitle(entry.key, l10n),
                      style: TextStyle(
                        fontSize: 12.fSize,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: entry.value / _questions.length,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontSize: 12.fSize,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
