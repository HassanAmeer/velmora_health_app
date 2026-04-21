import 'package:flutter/material.dart';
import 'package:velmora/services/game_service.dart';
import 'package:velmora/services/game_questions_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/widgets/game_progress_indicator.dart';
import 'package:velmora/widgets/skeletons/game_skeleton.dart';
import 'package:velmora/models/game_question.dart';
import 'package:velmora/services/vibration_service.dart';

class WouldYouRatherScreen extends StatefulWidget {
  const WouldYouRatherScreen({super.key});

  @override
  State<WouldYouRatherScreen> createState() => _WouldYouRatherScreenState();
}

class _WouldYouRatherScreenState extends State<WouldYouRatherScreen> {
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
      _sessionId = await _gameService.startGameSessionById('would_you_rather');
      final questions = await _questionsService.getQuestions(
        'would_you_rather',
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

  void _selectAnswer(String answer) {
    setState(() {
      if (_player1Answer == null) {
        _player1Answer = answer;
      } else if (_player2Answer == null) {
        _player2Answer = answer;
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
    const Color primaryColor = Color(0xFF673AB7);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(l10n.translate('would_you_rather')),
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
          title: Text(l10n.translate('would_you_rather')),

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
          title: Text(l10n.translate('would_you_rather')),

          elevation: 0,
        ),
        body: Padding(
          padding: EdgeInsets.all(24.adaptSize),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.help_outline, size: 80.adaptSize, color: primaryColor),
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
          title: Text(l10n.translate('would_you_rather')),

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
                l10n.gameComplete,
                style: TextStyle(
                  fontSize: 32.fSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2933),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                '${l10n.translate('questions_answered')} ${_questions.length} ${l10n.translate('questions_together')}',
                style: TextStyle(
                  fontSize: 18.fSize,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
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
    final optionA = currentQuestion.getLocalizedOptionA(Localizations.localeOf(context).languageCode) ?? 'Option A';
    final optionB = currentQuestion.getLocalizedOptionB(Localizations.localeOf(context).languageCode) ?? 'Option B';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(l10n.translate('would_you_rather')),

        elevation: 0,
      ),
      body: Column(
        children: [
          GameProgressIndicator(
            gameId: 'would_you_rather',
            current: _currentQuestionIndex + 1,
            total: _questions.length,
            color: primaryColor,
            label: '${l10n.questionOf} ${_currentQuestionIndex + 1} ${l10n.ofLabel} ${_questions.length}',
            trailingWidget: _showResults
                ? Text(
                    l10n.translate('both_answered'),
                    style: TextStyle(
                      fontSize: 13.fSize,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.adaptSize),
              child: Column(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 80.adaptSize,
                    color: primaryColor,
                  ),
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
                    child: Column(
                      children: [
                        Text(
                          l10n.translate('would_you_rather_ellipsis'),
                          style: TextStyle(
                            fontSize: 20.fSize,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 16.h),
                          Text(
                            currentQuestion.getLocalizedQuestion(Localizations.localeOf(context).languageCode),
                          style: TextStyle(
                            fontSize: 24.fSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2933),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),
                  if (!_showResults) ...[
                    _buildOption(optionA, 'A', primaryColor),
                    SizedBox(height: 16.h),
                    _buildOption(optionB, 'B', primaryColor),
                  ] else ...[
                    _buildResult(
                      optionA,
                      _player1Answer == 'A',
                      _player2Answer == 'A',
                    ),
                    SizedBox(height: 16.h),
                    _buildResult(
                      optionB,
                      _player1Answer == 'B',
                      _player2Answer == 'B',
                    ),
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
                          l10n.nextQuestion,
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

  Widget _buildOption(String text, String value, Color color) {
    final isSelected =
        (_player1Answer == value && _player2Answer == null) ||
        (_player2Answer == value && _player1Answer != null);
    final isDisabled = (_player1Answer != null && _player2Answer != null);

    return GestureDetector(
      onTap: isDisabled ? null : () => _selectAnswer(value),
      child: Container(
        padding: EdgeInsets.all(24.adaptSize),
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
            fontSize: 18.fSize,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : Colors.grey.shade700,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildResult(String text, bool player1, bool player2) {
    return Container(
      padding: EdgeInsets.all(20.adaptSize),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.adaptSize),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 16.fSize)),
          ),
          Row(
            children: [
              if (player1)
                Container(
                  padding: EdgeInsets.all(8.adaptSize),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppLocalizations.of(context).translate('player_1'),
                    style: TextStyle(fontSize: 12.fSize, color: Colors.blue),
                  ),
                ),
              if (player2)
                Container(
                  padding: EdgeInsets.all(8.adaptSize),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: EdgeInsets.only(left: 8.w),
                  child: Text(
                    AppLocalizations.of(context).translate('player_2'),
                    style: TextStyle(fontSize: 12.fSize, color: Colors.pink),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
