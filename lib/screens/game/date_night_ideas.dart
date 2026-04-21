import 'package:flutter/material.dart';
import 'package:velmora/services/game_service.dart';
import 'package:velmora/services/game_questions_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/widgets/game_progress_indicator.dart';
import 'package:velmora/widgets/skeletons/game_skeleton.dart';
import 'package:velmora/models/game_question.dart';
import 'package:velmora/services/vibration_service.dart';

class DateNightIdeasScreen extends StatefulWidget {
  const DateNightIdeasScreen({super.key});

  @override
  State<DateNightIdeasScreen> createState() => _DateNightIdeasScreenState();
}

class _DateNightIdeasScreenState extends State<DateNightIdeasScreen> {
  final GameService _gameService = GameService();
  final GameQuestionsService _questionsService = GameQuestionsService();
  final TextEditingController _player1Controller = TextEditingController();
  final TextEditingController _player2Controller = TextEditingController();

  List<GameQuestion> _ideas = [];
  int _currentIndex = 0;
  String? _sessionId;
  bool _isLoading = true;
  bool _gameCompleted = false;
  final List<int> _favoritedIndices = [];

  String _player1Name = 'Player 1';
  String _player2Name = 'Player 2';
  bool _namesSet = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      _sessionId = await _gameService.startGameSessionById('date_night_ideas');
      final ideas = await _questionsService.getQuestions('date_night_ideas');
      setState(() {
        _ideas = ideas;
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

  void _toggleFavorite(int index) {
    setState(() {
      if (_favoritedIndices.contains(index)) {
        _favoritedIndices.remove(index);
      } else {
        _favoritedIndices.add(index);
      }
    });
    VibrationService.vibration();
  }

  void _nextIdea() {
    if (_currentIndex < _ideas.length - 1) {
      setState(() {
        _currentIndex++;
      });
      VibrationService.vibration();
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
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorCompletingGame)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color primaryColor = Color(0xFFE91E63);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(l10n.translate('date_night_ideas')),
          elevation: 0,
        ),
        body: const GameScreenSkeleton(),
      );
    }

    if (_ideas.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9FF),
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(l10n.translate('date_night_ideas')),
          elevation: 0,
        ),
        body: Center(child: Text(l10n.translate('no_ideas_available'))),
      );
    }

    if (!_namesSet) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9FF),
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(l10n.translate('date_night_ideas')),
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
          title: Text(l10n.translate('date_night_ideas')),
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
                'Found ${_favoritedIndices.length} favorite ideas!',
                style: TextStyle(
                  fontSize: 32.fSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2933),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                'You explored ${_ideas.length} date night ideas together!',
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

    final currentIdea = _ideas[_currentIndex];
    final isFavorite = _favoritedIndices.contains(_currentIndex);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(l10n.translate('date_night_ideas')),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () => _toggleFavorite(_currentIndex),
          ),
        ],
      ),
      body: Column(
        children: [
          GameProgressIndicator(
            gameId: 'date_night_ideas',
            current: _currentIndex + 1,
            total: _ideas.length,
            color: primaryColor,
            label: '${l10n.translate('next_idea')} ${_currentIndex + 1} ${l10n.ofLabel} ${_ideas.length}',
            trailingWidget: Text(
              '${_favoritedIndices.length} ${l10n.translate('favorites')}',
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
                    Icons.restaurant,
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
                          currentIdea.getLocalizedTitle(Localizations.localeOf(context).languageCode) ?? currentIdea.getLocalizedQuestion(Localizations.localeOf(context).languageCode),
                          style: TextStyle(
                            fontSize: 24.fSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2933),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          currentIdea.getLocalizedDescription(Localizations.localeOf(context).languageCode) ?? '',
                          style: TextStyle(
                            fontSize: 16.fSize,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24.h),
                        if (currentIdea.budget != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${l10n.translate('budget')}: ${currentIdea.budget}',
                              style: TextStyle(
                                fontSize: 14.fSize,
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextIdea,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.adaptSize),
                  ),
                ),
                child: Text(
                  _currentIndex < _ideas.length - 1 ? 'Next Idea' : 'Finish',
                  style: TextStyle(fontSize: 18.fSize, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
