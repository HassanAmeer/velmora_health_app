import 'package:flutter/material.dart';
import 'package:velmora/services/game_service.dart';
import 'package:velmora/services/game_questions_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/widgets/game_progress_indicator.dart';
import 'package:velmora/widgets/skeletons/game_skeleton.dart';
import 'package:velmora/models/game_question.dart';
import 'package:velmora/services/vibration_service.dart';

class RelationshipQuizScreen extends StatefulWidget {
  const RelationshipQuizScreen({super.key});

  @override
  State<RelationshipQuizScreen> createState() => _RelationshipQuizScreenState();
}

class _RelationshipQuizScreenState extends State<RelationshipQuizScreen> {
  final GameService _gameService = GameService();
  final GameQuestionsService _questionsService = GameQuestionsService();
  final TextEditingController _player1Controller = TextEditingController();
  final TextEditingController _player2Controller = TextEditingController();

  List<GameQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  String? _sessionId;
  bool _isLoading = true;
  bool _gameCompleted = false;

  String _player1Name = 'Player 1';
  String _player2Name = 'Player 2';
  bool _namesSet = false;

  int _player1Score = 0;
  int _player2Score = 0;
  String? _player1Answer;
  String? _player2Answer;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      _sessionId = await _gameService.startGameSessionById('relationship_quiz');
      final questions = await _questionsService.getQuestions(
        'relationship_quiz',
      );
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
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

  void _selectAnswer(String answer, bool isCorrect) {
    setState(() {
      if (_player1Answer == null) {
        _player1Answer = answer;
        if (isCorrect) _player1Score++;
      } else if (_player2Answer == null) {
        _player2Answer = answer;
        if (isCorrect) _player2Score++;
        _showResults = true;
      }
    });
    VibrationService.vibration();
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _player1Answer = null;
        _player2Answer = null;
        _showResults = false;
      });
    } else {
      _finishGame();
    }
  }

  Future<void> _finishGame() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorCompletingGame),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color primaryColor = Color(0xFF00BCD4);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(l10n.translate('relationship_quiz')),
          elevation: 0,
        ),
        body: const GameScreenSkeleton(),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9FF),
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(l10n.translate('relationship_quiz')),

          elevation: 0,
        ),
        body: Center(child: Text(l10n.translate('no_questions_available'))),
      );
    }

    if (!_namesSet) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9FF),
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(l10n.translate('relationship_quiz')),

          elevation: 0,
        ),
        body: Padding(
          padding: EdgeInsets.all(24.adaptSize),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz, size: 80.adaptSize, color: primaryColor),
              SizedBox(height: 24.h),
              Text(
                l10n.enterPlayerNames,
                style: TextStyle(
                  fontSize: 28.fSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2933),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40.h),
              TextField(
                controller: _player1Controller,
                decoration: InputDecoration(
                  labelText: l10n.player1Name,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.adaptSize),
                  ),
                  filled: true,
                  fillColor: Colors.white,
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
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _setPlayerNames(l10n),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.adaptSize),
                    ),
                  ),
                  child: Text(
                    l10n.startGame,
                    style: TextStyle(fontSize: 18.fSize, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_gameCompleted) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9FF),
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(l10n.translate('relationship_quiz')),

          elevation: 0,
        ),
        body: Padding(
          padding: EdgeInsets.all(24.adaptSize),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.celebration, size: 100.adaptSize, color: primaryColor),
              SizedBox(height: 24.h),
              Text(
                l10n.quizComplete,
                style: TextStyle(
                  fontSize: 32.fSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2933),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              _buildScoreCard(_player1Name, _player1Score, Colors.blue),
              SizedBox(height: 16.h),
              _buildScoreCard(_player2Name, _player2Score, Colors.pink),
              SizedBox(height: 40.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.adaptSize),
                    ),
                  ),
                  child: Text(
                    l10n.backToGames,
                    style: TextStyle(fontSize: 18.fSize, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final question = currentQuestion.getLocalizedQuestion(Localizations.localeOf(context).languageCode);
    final options = currentQuestion.options ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(l10n.translate('relationship_quiz')),

        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(24.adaptSize),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.questionOf} ${_currentQuestionIndex + 1} ${l10n.ofLabel} ${_questions.length}',
                      style: TextStyle(
                        fontSize: 14.fSize,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Row(
                      children: [
                        _buildMiniScore(
                          _player1Name,
                          _player1Score,
                          Colors.blue,
                        ),
                        SizedBox(width: 16.w),
                        _buildMiniScore(
                          _player2Name,
                          _player2Score,
                          Colors.pink,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
          GameProgressIndicator(
            gameId: 'relationship_quiz',
            current: _currentQuestionIndex + 1,
            total: _questions.length,
            color: primaryColor,
            label: '${l10n.questionOf} ${_currentQuestionIndex + 1} ${l10n.ofLabel} ${_questions.length}',
            trailingWidget: Row(
              children: [
                _buildMiniScore(_player1Name, _player1Score, Colors.blue),
                SizedBox(width: 16.w),
                _buildMiniScore(_player2Name, _player2Score, Colors.pink),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.adaptSize),
              child: Column(
                children: [
                  Icon(Icons.quiz, size: 80.adaptSize, color: primaryColor),
                  SizedBox(height: 24.h),
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
                    child: Text(
                      question,
                      style: TextStyle(
                        fontSize: 20.fSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2933),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 32.h),
                  if (!_showResults) ...[
                    ...options.map((option) {
                      final isCorrect = option.isCorrect;
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: _buildOption(option.getLocalizedText(Localizations.localeOf(context).languageCode), isCorrect, primaryColor),
                      );
                    }),
                  ] else ...[
                    _buildResults(options, primaryColor),
                    SizedBox(height: 32.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.adaptSize),
                          ),
                        ),
                        child: Text(
                          _currentQuestionIndex < _questions.length - 1
                              ? l10n.nextQuestion
                              : l10n.translate('see_results'),
                          style: TextStyle(
                            fontSize: 18.fSize,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String name, int score, Color color) {
    return Container(
      padding: EdgeInsets.all(24.adaptSize),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.adaptSize),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Text(
              name[0],
              style: TextStyle(color: color, fontSize: 24.fSize),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 18.fSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${AppLocalizations.of(context).translate('score')}: $score',
                  style: TextStyle(fontSize: 16.fSize, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniScore(String name, int score, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$name: $score',
        style: TextStyle(
          fontSize: 12.fSize,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOption(String text, bool isCorrect, Color color) {
    final isSelected = _player1Answer == text || _player2Answer == text;
    final isDisabled = _showResults;

    return GestureDetector(
      onTap: isDisabled ? null : () => _selectAnswer(text, isCorrect),
      child: Container(
        padding: EdgeInsets.all(20.adaptSize),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16.adaptSize),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16.fSize,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildResults(List<QuizOption> options, Color color) {
    return Column(
      children: options.map((option) {
        final isCorrect = option.isCorrect;
        final p1Selected = _player1Answer == option.text;
        final p2Selected = _player2Answer == option.text;

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.adaptSize),
          decoration: BoxDecoration(
            color: isCorrect
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.adaptSize),
          ),
          child: Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.grey,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  option.getLocalizedText(Localizations.localeOf(context).languageCode),
                  style: TextStyle(
                    fontSize: 14.fSize,
                    color: isCorrect ? Colors.green : Colors.grey,
                  ),
                ),
              ),
              if (p1Selected)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppLocalizations.of(context).translate('player_1'),
                    style: TextStyle(fontSize: 10.fSize, color: Colors.blue),
                  ),
                ),
              if (p2Selected)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: EdgeInsets.only(left: 8.w),
                  child: Text(
                    AppLocalizations.of(context).translate('player_2'),
                    style: TextStyle(fontSize: 10.fSize, color: Colors.pink),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
