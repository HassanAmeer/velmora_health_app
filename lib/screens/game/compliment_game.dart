import 'package:flutter/material.dart';
import 'package:velmora/services/game_service.dart';
import 'package:velmora/services/game_questions_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/widgets/game_progress_indicator.dart';
import 'package:velmora/widgets/skeletons/game_skeleton.dart';
import 'package:velmora/models/game_question.dart';
import 'package:velmora/services/vibration_service.dart';

class ComplimentGameScreen extends StatefulWidget {
  const ComplimentGameScreen({super.key});

  @override
  State<ComplimentGameScreen> createState() => _ComplimentGameScreenState();
}

class _ComplimentGameScreenState extends State<ComplimentGameScreen> {
  final GameService _gameService = GameService();
  final GameQuestionsService _questionsService = GameQuestionsService();
  final TextEditingController _player1Controller = TextEditingController();
  final TextEditingController _player2Controller = TextEditingController();

  List<GameQuestion> _prompts = [];
  int _currentIndex = 0;
  String? _sessionId;
  bool _isLoading = true;
  bool _gameCompleted = false;

  String _player1Name = 'Player 1';
  String _player2Name = 'Player 2';
  bool _namesSet = false;
  bool _isPlayer1Turn = true;

  final List<String> _givenCompliments = [];

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      _sessionId = await _gameService.startGameSessionById('compliment_game');
      final prompts = await _questionsService.getQuestions('compliment_game');
      setState(() {
        _prompts = prompts;
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

  void _giveCompliment() {
    final complimentGiver = _isPlayer1Turn ? _player1Name : _player2Name;
    setState(() {
      _givenCompliments.add('$complimentGiver gave a compliment!');
      _isPlayer1Turn = !_isPlayer1Turn;
    });
    VibrationService.vibration();

    if (_currentIndex < _prompts.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finishGame();
    }
  }

  void _skipTurn() {
    setState(() {
      _isPlayer1Turn = !_isPlayer1Turn;
    });

    if (_currentIndex < _prompts.length - 1) {
      setState(() {
        _currentIndex++;
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
    const Color primaryColor = Color(0xFF9C27B0);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(l10n.translate('compliment_game')),
          elevation: 0,
        ),
        body: const GameScreenSkeleton(),
      );
    }

    if (_prompts.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9FF),
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(l10n.translate('compliment_game')),

          elevation: 0,
        ),
        body: Center(child: Text(l10n.translate('no_prompts_available'))),
      );
    }

    if (!_namesSet) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9FF),
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(l10n.translate('compliment_game')),

          elevation: 0,
        ),
        body: Padding(
          padding: EdgeInsets.all(24.adaptSize),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite, size: 80.adaptSize, color: primaryColor),
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
          title: Text(l10n.translate('compliment_game')),

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
                l10n.translate('so_much_love'),
                style: TextStyle(
                  fontSize: 32.fSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2933),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                l10n
                    .translate('you_shared_compliments')
                    .replaceAll('{count}', _givenCompliments.length.toString()),
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

    final currentPrompt = _prompts[_currentIndex];
    final currentPlayer = _isPlayer1Turn ? _player1Name : _player2Name;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(l10n.translate('compliment_game')),

        elevation: 0,
      ),
      body: Column(
        children: [
          GameProgressIndicator(
            gameId: 'compliment_game',
            current: _currentIndex + 1,
            total: _prompts.length,
            color: primaryColor,
            label: '${l10n.translate('round')} ${_currentIndex + 1} ${l10n.ofLabel} ${_prompts.length}',
            trailingWidget: Text(
              '${_givenCompliments.length} ${l10n.translate('compliments')}',
              style: TextStyle(
                fontSize: 13.fSize,
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.adaptSize),
              child: Column(
                children: [
                  Icon(
                    Icons.card_giftcard,
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
                          l10n
                              .translate('give_a_compliment_prompt')
                              .replaceAll('{name}', currentPlayer),
                          style: TextStyle(
                            fontSize: 16.fSize,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 16.h),
                         Text(
                           currentPrompt.getLocalizedQuestion(Localizations.localeOf(context).languageCode),
                          style: TextStyle(
                            fontSize: 22.fSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2933),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        if (currentPrompt.hint != null)
                           Text(
                             '${l10n.translate('hint')}: ${currentPrompt.getLocalizedHint(Localizations.localeOf(context).languageCode) ?? ''}',
                            style: TextStyle(
                              fontSize: 14.fSize,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(24.adaptSize),
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _giveCompliment,
                    icon: Icon(Icons.favorite, color: Colors.white),
                    label: Text(
                      l10n.translate('give_a_compliment'),
                      style: TextStyle(fontSize: 18.fSize, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.adaptSize),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _skipTurn,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.adaptSize),
                      ),
                    ),
                    child: Text(
                      l10n.translate('skip_turn'),
                      style: TextStyle(
                        fontSize: 18.fSize,
                        color: Colors.grey.shade600,
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
