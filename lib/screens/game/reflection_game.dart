import 'package:flutter/material.dart';
import 'package:velmora/services/game_service.dart';
import 'package:velmora/services/game_questions_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/widgets/skeletons/game_skeleton.dart';
import 'package:velmora/models/game_question.dart';
import 'package:velmora/services/vibration_service.dart';

class ReflectionGameScreen extends StatefulWidget {
  const ReflectionGameScreen({super.key});

  @override
  State<ReflectionGameScreen> createState() => _ReflectionGameScreenState();
}

class _ReflectionGameScreenState extends State<ReflectionGameScreen> {
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

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      _sessionId = await _gameService.startGameSessionById('reflection_game');

      // Load questions using the new service
      final questions = await _questionsService.getQuestions('reflection_game');

      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    }
  }

  List<Map<String, dynamic>> _getDefaultQuestions() {
    return [
      {
        'id': '1',
        'question':
            'What is one thing you would like to improve about yourself in the next year?',
        'category': 'personal_growth',
        'prompt':
            'Share your thoughts and discuss how you can support each other.',
      },
      {
        'id': '2',
        'question': 'What does a perfect day together look like to you?',
        'category': 'dreams',
        'prompt': 'Describe in detail and find common elements.',
      },
      {
        'id': '3',
        'question':
            'What is one fear or worry you have about our future together?',
        'category': 'vulnerability',
        'prompt': 'Be honest and supportive as you listen.',
      },
      {
        'id': '4',
        'question':
            'What tradition or ritual would you like us to start as a couple?',
        'category': 'connection',
        'prompt': 'Brainstorm ideas together.',
      },
      {
        'id': '5',
        'question': 'When do you feel most loved by me?',
        'category': 'love',
        'prompt': 'Share specific moments or actions.',
      },
      {
        'id': '6',
        'question': 'What is one thing I do that makes you feel appreciated?',
        'category': 'appreciation',
        'prompt': 'Express gratitude and discuss.',
      },
      {
        'id': '7',
        'question':
            'What is a challenge we have overcome together that made us stronger?',
        'category': 'resilience',
        'prompt': 'Reflect on how you worked through it.',
      },
      {
        'id': '8',
        'question': 'What is one goal you have for our relationship this year?',
        'category': 'goals',
        'prompt': 'Discuss how to achieve it together.',
      },
      {
        'id': '9',
        'question': 'What is something new you would like to try together?',
        'category': 'adventure',
        'prompt': 'Be creative and open-minded.',
      },
      {
        'id': '10',
        'question': 'How can I better support you during difficult times?',
        'category': 'support',
        'prompt': 'Be specific about what helps you most.',
      },
    ];
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
    final playerName = _isPlayer1Turn ? _player1Name : _player2Name;

    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseEnterAnswer)));
      return;
    }

    setState(() {
      if (!_answers.containsKey(_currentQuestionIndex)) {
        _answers[_currentQuestionIndex] = {};
      }

      if (_isPlayer1Turn) {
        _answers[_currentQuestionIndex]!['player1'] = controller.text.trim();
        _isPlayer1Turn = false;
      } else {
        _answers[_currentQuestionIndex]!['player2'] = controller.text.trim();
        _isPlayer1Turn = true;

        // Both players answered, move to next question
        if (_currentQuestionIndex < _questions.length - 1) {
          _currentQuestionIndex++;
        } else {
          _gameCompleted = true;
          _completeGame();
        }
      }

    });
    VibrationService.vibration();
    controller.clear();
  }

  Future<void> _completeGame() async {
    if (_sessionId != null) {
      await _gameService.completeGameSession(_sessionId!);
    }
    VibrationService.longVibration();
  }

  void _restartGame() {
    setState(() {
      _currentQuestionIndex = 0;
      _answers.clear();
      _gameCompleted = false;
      _isPlayer1Turn = true;
      _player1Controller.clear();
      _player2Controller.clear();
    });
    _initializeGame();
  }

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.reflectionDiscussionGame)),
        body: const GameScreenSkeleton(),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.reflectionDiscussionGame)),
        body: Center(child: Text(l10n.errorLoadingGame)),
      );
    }

    if (!_namesSet) {
      return _buildNameInputScreen(l10n);
    }

    if (_gameCompleted) {
      return _buildCompletionScreen(l10n);
    }

    return _buildGameScreen(l10n);
  }

  Widget _buildNameInputScreen(AppLocalizations l10n) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reflectionDiscussionGame)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20.h),
            Text(
              l10n.welcomeToReflection,
              style: TextStyle(fontSize: 18.fSize, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            Text(
              l10n.reflectionWelcomeDesc,
              style: TextStyle(fontSize: 18.fSize, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: _player1Controller,
              decoration: InputDecoration(
                labelText: l10n.player1Name,
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: _player2Controller,
              decoration: InputDecoration(
                labelText: l10n.player2Name,
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () => _setPlayerNames(l10n),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 20.h),
              ),
              child: Text(l10n.startGame, style: TextStyle(fontSize: 18.fSize)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen(AppLocalizations l10n) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final currentPlayer = _isPlayer1Turn ? _player1Name : _player2Name;
    final controller = _isPlayer1Turn ? _player1Controller : _player2Controller;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reflectionDiscussionGame),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                '${l10n.questionCount} ${_currentQuestionIndex + 1}/${_questions.length}',
                style: TextStyle(fontSize: 18.fSize),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? '${l10n.sTurn} $currentPlayer'
                    : '$currentPlayer ${l10n.sTurn}',
                style: TextStyle(
                  fontSize: 18.fSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.shade200, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    currentQuestion.getLocalizedQuestion(
                      Localizations.localeOf(context).languageCode,
                    ),
                    style: TextStyle(
                      fontSize: 18.fSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (currentQuestion.prompt != null) ...[
                    SizedBox(height: 20.h),
                    Text(
                      currentQuestion.getLocalizedPrompt(
                            Localizations.localeOf(context).languageCode,
                          ) ??
                          '',
                      style: TextStyle(
                        fontSize: 18.fSize,
                        color: Colors.purple.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: l10n.yourAnswer,
                hintText: l10n.shareThoughts,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () => _submitAnswer(l10n),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 20.h),
              ),
              child: Text(
                l10n.submitAnswer,
                style: TextStyle(fontSize: 18.fSize),
              ),
            ),
            if (_answers.containsKey(_currentQuestionIndex) &&
                _answers[_currentQuestionIndex]!.containsKey('player1')) ...[
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_player1Name${l10n.sAnswer}',
                      style: TextStyle(
                        fontSize: 18.fSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      _answers[_currentQuestionIndex]!['player1']!,
                      style: TextStyle(
                        fontSize: 18.fSize,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionScreen(AppLocalizations l10n) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.gameComplete)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20.h),
            Icon(Icons.favorite, size: 18.fSize, color: Colors.red),
            SizedBox(height: 20.h),
            Text(
              l10n.congratulations,
              style: TextStyle(fontSize: 18.fSize, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            Text(
              l10n.gameCompletedReflection,
              style: TextStyle(fontSize: 18.fSize, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            Text(
              '${l10n.questionsAnswered} ${_questions.length} ${l10n.questionsTogether}',
              style: TextStyle(fontSize: 18.fSize, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: _restartGame,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 20.h),
              ),
              child: Text(l10n.playAgain, style: TextStyle(fontSize: 18.fSize)),
            ),
            SizedBox(height: 20.h),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 20.h),
              ),
              child: Text(
                l10n.backToGames,
                style: TextStyle(fontSize: 18.fSize),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
