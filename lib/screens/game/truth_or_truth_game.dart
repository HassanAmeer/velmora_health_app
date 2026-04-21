import 'package:flutter/material.dart';
import 'package:velmora/services/game_service.dart';
import 'package:velmora/services/game_questions_service.dart';
import 'package:velmora/services/error_cache_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/widgets/game_progress_indicator.dart';
import 'package:velmora/widgets/skeletons/game_skeleton.dart';
import 'package:velmora/models/game_question.dart';
import 'package:velmora/services/vibration_service.dart';

class TruthOrTruthGameScreen extends StatefulWidget {
  const TruthOrTruthGameScreen({super.key});

  @override
  State<TruthOrTruthGameScreen> createState() => _TruthOrTruthGameScreenState();
}

class _TruthOrTruthGameScreenState extends State<TruthOrTruthGameScreen> {
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

  // Answers storage
  final Map<int, Map<String, String>> _answers = {};

  // Scores
  int _player1Score = 0;
  int _player2Score = 0;

  @override
  void initState() {
    super.initState();
    // Initialize game after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  Future<void> _initializeGame() async {
    try {
      print('🎮 [TruthOrTruth] Starting initialization...');

      // Start game session
      print('🎮 [TruthOrTruth] Starting game session...');
      try {
        _sessionId = await _gameService.startGameSessionById('truth_or_truth');
        print('🎮 [TruthOrTruth] Session ID: $_sessionId');
      } catch (e) {
        print('❌ [TruthOrTruth] Failed to start session: $e');
        await ErrorCacheService().logGameError(
          gameId: 'truth_or_truth',
          phase: 'start_session',
          error: e.toString(),
          stack: StackTrace.current.toString(),
        );
        // Continue anyway - session is not critical for gameplay
        _sessionId = null;
      }

      // Load questions using the new service
      print('🎮 [TruthOrTruth] Loading questions...');
      final questions = await _questionsService.getQuestions('truth_or_truth');
      print('🎮 [TruthOrTruth] Loaded ${questions.length} questions');

      // Validate questions
      if (questions.isEmpty) {
        throw Exception('No questions loaded for truth_or_truth');
      }

      if (!mounted) return;

      setState(() {
        _questions = questions;
        _isLoading = false;
      });

      print('✅ [TruthOrTruth] Initialization complete');
    } catch (e, stackTrace) {
      print('❌ [TruthOrTruth] Initialization error: $e');
      print('❌ [TruthOrTruth] Stack trace: $stackTrace');

      // Cache the error
      await ErrorCacheService().logGameError(
        gameId: 'truth_or_truth',
        phase: 'initialization',
        error: e.toString(),
        stack: stackTrace.toString(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Check if error contains user-friendly message
      String errorMessage = e.toString();
      bool isUserError =
          errorMessage.contains('User not logged in') ||
          errorMessage.contains('sign in');

      if (mounted) {
        if (isUserError) {
          // Show user-friendly message and navigate back
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Sign In Required'),
              content: const Text(
                'You need to be signed in to play games. Please sign in and try again.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to games
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.error}: $e'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
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

  void _submitAnswer(AppLocalizations l10n) {
    final controller = _isPlayer1Turn ? _player1Controller : _player2Controller;
    final answer = controller.text.trim();

    if (answer.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseEnterAnswer)));
      return;
    }

    // Store answer
    if (_answers[_currentQuestionIndex] == null) {
      _answers[_currentQuestionIndex] = {};
    }

    if (_isPlayer1Turn) {
      _answers[_currentQuestionIndex]!['player1'] = answer;
      // Award point for answering
      _player1Score++;
    } else {
      _answers[_currentQuestionIndex]!['player2'] = answer;
      // Award point for answering
      _player2Score++;
    }

    controller.clear();
    VibrationService.vibration();

    // Check if both players answered
    if (_answers[_currentQuestionIndex]!.length == 2) {
      // Both answered, move to next question
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _isPlayer1Turn = true;
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
  }

  void _skipQuestion(AppLocalizations l10n) {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isPlayer1Turn = true;
        _player1Controller.clear();
        _player2Controller.clear();
      });
    } else {
      _completeGame(l10n);
    }
  }

  Future<void> _completeGame(AppLocalizations l10n) async {
    try {
      if (_sessionId != null) {
        await _gameService.completeGameSession(_sessionId!);
      }
      setState(() {
        _gameCompleted = true;
      });
      VibrationService.longVibration();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorCompletingGame)));
      }
    }
  }

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  Color get _primaryColor => const Color(0xFFFF4D8D);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: _primaryColor,
          title: Text(l10n.translate('truth_or_truth')),
          elevation: 0,
        ),
        body: const GameScreenSkeleton(),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: _primaryColor,
          title: Text(l10n.translate('truth_or_truth')),
          elevation: 0,
        ),
        body: Center(child: Text(l10n.errorLoadingGame)),
      );
    }

    // Player names input screen
    if (!_namesSet) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9FF),
        appBar: AppBar(
          backgroundColor: _primaryColor,
          title: Text(l10n.truthOrTruth),
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
                l10n.enterNames,
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
                    l10n.startGame,
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
      final winner = _player1Score > _player2Score
          ? _player1Name
          : _player2Score > _player1Score
          ? _player2Name
          : 'Tie';

      return Scaffold(
        backgroundColor: const Color(0xFFF9F9FF),
        appBar: AppBar(
          backgroundColor: _primaryColor,
          title: Text(l10n.truthOrTruth),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.adaptSize),
            child: Column(
              children: [
                SizedBox(height: 20.h),
                Icon(
                  Icons.emoji_events,
                  size: 80.adaptSize,
                  color: _primaryColor,
                ),
                SizedBox(height: 24.h),
                Text(
                  winner == 'Tie' ? l10n.itsATie : '$winner ${l10n.wins}',
                  style: TextStyle(
                    fontSize: 28.fSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2933),
                  ),
                ),
                SizedBox(height: 32.h),
                Container(
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
                    children: [
                      Text(
                        l10n.finalScores,
                        style: TextStyle(
                          fontSize: 20.fSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2933),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                _player1Name,
                                style: TextStyle(
                                  fontSize: 16.fSize,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                '$_player1Score',
                                style: TextStyle(
                                  fontSize: 32.fSize,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            l10n.vs,
                            style: TextStyle(
                              fontSize: 20.fSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                _player2Name,
                                style: TextStyle(
                                  fontSize: 16.fSize,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                '$_player2Score',
                                style: TextStyle(
                                  fontSize: 32.fSize,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
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
    final currentPlayer = _isPlayer1Turn ? _player1Name : _player2Name;
    final currentController = _isPlayer1Turn
        ? _player1Controller
        : _player2Controller;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        // title: Text(l10n.truthOrTruth),
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w, left: 16.w),
            child: Center(
              child: Text(
                '$_player1Score - $_player2Score',
                style: TextStyle(
                  fontSize: 18.fSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          GameProgressIndicator(
            gameId: 'truth_or_truth',
            current: _currentQuestionIndex + 1,
            total: _questions.length,
            color: _primaryColor,
            label:
                '${l10n.questionCount} ${_currentQuestionIndex + 1} ${l10n.ofLabel} ${_questions.length}',
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

          // Question and answer area
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.adaptSize),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(32.adaptSize),
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
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 60.adaptSize,
                          color: _primaryColor,
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          currentQuestion.getLocalizedQuestion(
                            Localizations.localeOf(context).languageCode,
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22.fSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2933),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  TextField(
                    controller: currentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: l10n.yourAnswer,
                      hintText: l10n.typeAnswerHere,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.adaptSize),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: EdgeInsets.all(24.adaptSize),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _skipQuestion(l10n),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.adaptSize),
                      ),
                    ),
                    child: Text(
                      l10n.skip,
                      style: TextStyle(
                        fontSize: 16.fSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _submitAnswer(l10n),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
