import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velmora/services/game_service.dart';
import 'package:velmora/services/game_questions_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/widgets/game_progress_indicator.dart';
import 'package:velmora/widgets/skeletons/game_skeleton.dart';
import 'package:velmora/services/vibration_service.dart';

class DeepDialogueWheelScreen extends StatefulWidget {
  const DeepDialogueWheelScreen({super.key});

  @override
  State<DeepDialogueWheelScreen> createState() =>
      _DeepDialogueWheelScreenState();
}

class _CategoryData {
  final String id;
  final String label;
  final String emoji;
  final Color color;

  const _CategoryData({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
  });
}

const List<_CategoryData> _categories = [
  _CategoryData(
    id: 'emotional_connection',
    label: 'Emotional Connection',
    emoji: '\u2764\uFE0F',
    color: Color(0xFFE91E63),
  ),
  _CategoryData(
    id: 'shared_dreams',
    label: 'Shared Dreams',
    emoji: '\u2B50',
    color: Color(0xFF9C27B0),
  ),
  _CategoryData(
    id: 'conflict_resolution',
    label: 'Conflict Resolution',
    emoji: '\uD83E\uDD1D',
    color: Color(0xFFFF9800),
  ),
  _CategoryData(
    id: 'playful_memories',
    label: 'Playful Memories',
    emoji: '\uD83C\uDF89',
    color: Color(0xFF4CAF50),
  ),
  _CategoryData(
    id: 'building_the_future',
    label: 'Building the Future',
    emoji: '\uD83C\uDF1F',
    color: Color(0xFF2196F3),
  ),
  _CategoryData(
    id: 'values_and_principles',
    label: 'Values & Principles',
    emoji: '\uD83D\uDD35',
    color: Color(0xFF00BCD4),
  ),
];

class _SessionEntry {
  final int spinNumber;
  final String category;
  final String question;

  _SessionEntry({
    required this.spinNumber,
    required this.category,
    required this.question,
  });

  Map<String, dynamic> toJson() => {
    'spinNumber': spinNumber,
    'category': category,
    'question': question,
  };
}

class _DeepDialogueWheelScreenState extends State<DeepDialogueWheelScreen>
    with SingleTickerProviderStateMixin {
  final GameService _gameService = GameService();
  final GameQuestionsService _questionsService = GameQuestionsService();
  final TextEditingController _player1Controller = TextEditingController();
  final TextEditingController _player2Controller = TextEditingController();

  String? _sessionId;
  bool _isLoading = true;

  String _player1Name = 'Partner A';
  String _player2Name = 'Partner B';
  bool _namesSet = false;

  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  double _currentAngle = 0;
  double _randomSpinTarget = 0;
  bool _isSpinning = false;
  bool _showCategoryResult = false;
  int? _selectedCategoryIndex;
  String? _currentQuestion;
  String? _currentCategory;
  int _roundsPlayed = 0;
  static const int _maxRounds = 8;
  bool _gameCompleted = false;
  bool _showSummary = false;
  bool _spinAgainMode = false;

  final List<_SessionEntry> _sessionHistory = [];
  final Set<String> _categoriesAppeared = {};

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    );
    _spinController.addListener(_onSpinUpdate);
    _spinController.addStatusListener(_onSpinStatus);
    _initializeGame();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  Future<void> _initializeGame() async {
    try {
      _sessionId = await _gameService.startGameSessionById(
        'deep_dialogue_wheel',
      );
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
        );
      }
    }
  }

  void _onSpinUpdate() {
    setState(() {
      _currentAngle = _spinAnimation.value * 2 * pi * 5 + _randomSpinTarget;
    });
  }

  void _onSpinStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      final categoryIndex = _determineCategory();
      final category = _categories[categoryIndex];
      _categoriesAppeared.add(category.id);
      setState(() {
        _isSpinning = false;
        _selectedCategoryIndex = categoryIndex;
        _currentCategory = category.id;
        _showCategoryResult = true;
      });
      VibrationService.longVibration();
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _showCategoryResult = false);
          _generateQuestion(category.id);
        }
      });
    }
  }

  int _determineCategory() {
    final finalAngle = (_currentAngle % (2 * pi) + 2 * pi) % (2 * pi);
    final segmentAngle = (2 * pi) / _categories.length;
    int index = ((-finalAngle / segmentAngle).floor()) % _categories.length;
    if (index < 0) index += _categories.length;
    if (_categories[index].id == _currentCategory && _roundsPlayed > 0) {
      index = (index + 1) % _categories.length;
    }
    return index;
  }

  Future<void> _generateQuestion(String categoryId) async {
    final question = await _questionsService.generateWheelQuestion(categoryId);
    if (question != null && mounted) {
      setState(() {
        _currentQuestion = question.question;
      });
    } else if (mounted) {
      setState(() {
        _currentQuestion =
            'What is something you appreciate about our relationship right now?';
      });
    }
  }

  void _spin() {
    if (_isSpinning || _roundsPlayed >= _maxRounds) return;
    final random = Random();
    _randomSpinTarget = 2 * pi * random.nextDouble();
    setState(() {
      _isSpinning = true;
      _currentQuestion = null;
      _selectedCategoryIndex = null;
      _currentCategory = null;
      _showCategoryResult = false;
    });
    VibrationService.doubleVibration();
    _spinController.forward(from: 0);
  }

  void _nextSpin() {
    if (_currentQuestion == null || _currentCategory == null) return;

    _sessionHistory.add(
      _SessionEntry(
        spinNumber: _roundsPlayed + 1,
        category: _currentCategory!,
        question: _currentQuestion!,
      ),
    );

    if (_roundsPlayed >= _maxRounds - 1) {
      _saveSessionToLocal();
      setState(() => _showSummary = true);
      return;
    }
    setState(() {
      _roundsPlayed++;
      _currentQuestion = null;
      _selectedCategoryIndex = null;
      _currentCategory = null;
      _currentAngle = 0;
    });
    VibrationService.lightVibration();
  }

  Future<void> _saveSessionToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyKey =
          'wheel_session_${DateTime.now().millisecondsSinceEpoch}';
      final data = _sessionHistory.map((e) => e.toJson()).toList();
      await prefs.setString(historyKey, jsonEncode(data));
    } catch (e) {
      // silently fail — history is nice-to-have
    }
  }

  Future<void> _finishGame() async {
    try {
      if (_sessionId != null) {
        await _gameService.completeGameSession(_sessionId!);
      }
      setState(() => _gameCompleted = true);
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

  void _resetForNewSession() {
    setState(() {
      _roundsPlayed = 0;
      _currentQuestion = null;
      _selectedCategoryIndex = null;
      _currentCategory = null;
      _currentAngle = 0;
      _showSummary = false;
      _spinAgainMode = true;
      _sessionHistory.clear();
      _categoriesAppeared.clear();
    });
    VibrationService.doubleVibration();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color defaultColor = Color(0xFF6C63FF);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: defaultColor,
          title: Text(l10n.translate('deep_dialogue_wheel')),
          elevation: 0,
        ),
        body: const GameScreenSkeleton(),
      );
    }

    if (!_namesSet) {
      return _buildNameScreen(l10n, defaultColor);
    }

    if (_gameCompleted) {
      return _buildCompletionScreen(l10n, defaultColor);
    }

    if (_showSummary) {
      return _buildSummaryScreen(l10n, defaultColor);
    }

    if (_currentQuestion != null && _selectedCategoryIndex != null) {
      return _buildQuestionScreen(l10n, defaultColor);
    }

    return _buildWheelScreen(l10n, defaultColor);
  }

  Widget _buildNameScreen(AppLocalizations l10n, Color defaultColor) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: defaultColor,
        title: Text(l10n.translate('deep_dialogue_wheel')),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(24.adaptSize),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 80.adaptSize, color: defaultColor),
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
            SizedBox(height: 8.h),
            Text(
              l10n.translate('wheel_name_subtitle'),
              style: TextStyle(fontSize: 14.fSize, color: Colors.grey.shade600),
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
                  backgroundColor: defaultColor,
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

  Widget _buildCompletionScreen(AppLocalizations l10n, Color defaultColor) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: defaultColor,
        title: Text(l10n.translate('deep_dialogue_wheel')),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(24.adaptSize),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration, size: 100.adaptSize, color: defaultColor),
            SizedBox(height: 24.h),
            Text(
              l10n.translate('wonderful_discussions'),
              style: TextStyle(
                fontSize: 32.fSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2933),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.translate('thank_you_spinning'),
              style: TextStyle(fontSize: 18.fSize, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: defaultColor,
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

  Widget _buildWheelScreen(AppLocalizations l10n, Color defaultColor) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: defaultColor,
        title: Text(l10n.translate('deep_dialogue_wheel')),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              GameProgressIndicator(
                gameId: 'deep_dialogue_wheel',
                current: _roundsPlayed + 1,
                total: _maxRounds,
                color: defaultColor,
                label:
                    '${l10n.translate('spin')} ${_roundsPlayed + 1} ${l10n.ofLabel} $_maxRounds',
                trailingWidget: Text(
                  '$_player1Name & $_player2Name',
                  style: TextStyle(
                    fontSize: 13.fSize,
                    color: defaultColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 300.adaptSize,
                        height: 300.adaptSize,
                        child: GestureDetector(
                          onTap: _isSpinning ? null : _spin,
                          child: AnimatedBuilder(
                            animation: _spinAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                size: Size(300.adaptSize, 300.adaptSize),
                                painter: _WheelPainter(
                                  categories: _categories,
                                  selectedIndex: _selectedCategoryIndex,
                                  appearedCategories: _categoriesAppeared,
                                  rotationAngle: _currentAngle,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        _isSpinning
                            ? l10n.translate('spinning')
                            : l10n.translate('tap_wheel_or_button'),
                        style: TextStyle(
                          fontSize: 16.fSize,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (_selectedCategoryIndex != null) ...[
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.adaptSize,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: _categories[_selectedCategoryIndex!].color
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20.adaptSize),
                          ),
                          child: Text(
                            '${_categories[_selectedCategoryIndex!].emoji} ${_categories[_selectedCategoryIndex!].label}',
                            style: TextStyle(
                              fontSize: 14.fSize,
                              fontWeight: FontWeight.bold,
                              color: _categories[_selectedCategoryIndex!].color,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 8.h),
                      Text(
                        '${l10n.translate('round')} ${_roundsPlayed + 1} ${l10n.ofLabel} $_maxRounds',
                        style: TextStyle(
                          fontSize: 14.fSize,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      if (_spinAgainMode)
                        Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.adaptSize,
                              vertical: 4.adaptSize,
                            ),
                            decoration: BoxDecoration(
                              color: defaultColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.adaptSize),
                            ),
                            child: Text(
                              l10n.translate('spin_again_session'),
                              style: TextStyle(
                                fontSize: 12.fSize,
                                color: defaultColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(20.adaptSize),
                color: Colors.white,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSpinning ? null : _spin,
                    icon: Icon(
                      Icons.touch_app,
                      color: _isSpinning ? Colors.grey : Colors.white,
                    ),
                    label: Text(
                      _isSpinning
                          ? l10n.translate('spinning')
                          : (_roundsPlayed == 0
                                ? l10n.translate('first_spin')
                                : l10n.translate('spin_again')),
                      style: TextStyle(
                        fontSize: 18.fSize,
                        color: _isSpinning ? Colors.grey : Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSpinning
                          ? Colors.grey.shade300
                          : defaultColor,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.adaptSize),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showCategoryResult && _selectedCategoryIndex != null)
            _buildCategoryResultOverlay(l10n),
        ],
      ),
    );
  }

  Widget _buildCategoryResultOverlay(AppLocalizations l10n) {
    final cat = _categories[_selectedCategoryIndex!];
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                margin: EdgeInsets.all(40.adaptSize),
                padding: EdgeInsets.all(32.adaptSize),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.adaptSize),
                  boxShadow: [
                    BoxShadow(
                      color: cat.color.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat.emoji, style: TextStyle(fontSize: 64.adaptSize)),
                    SizedBox(height: 16.h),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 24.fSize,
                        fontWeight: FontWeight.bold,
                        color: cat.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      l10n.translate('selected'),
                      style: TextStyle(
                        fontSize: 14.fSize,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuestionScreen(AppLocalizations l10n, Color defaultColor) {
    final category = _categories[_selectedCategoryIndex!];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: category.color,
        title: Text(l10n.translate('deep_dialogue_wheel')),
        elevation: 0,
      ),
      body: Column(
        children: [
          GameProgressIndicator(
            gameId: 'deep_dialogue_wheel',
            current: _roundsPlayed + 1,
            total: _maxRounds,
            color: category.color,
            label:
                '${l10n.translate('spin')} ${_roundsPlayed + 1} ${l10n.ofLabel} $_maxRounds',
            trailingWidget: Text(
              category.label,
              style: TextStyle(
                fontSize: 13.fSize,
                color: category.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.adaptSize),
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  Container(
                    width: 100.adaptSize,
                    height: 100.adaptSize,
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        category.emoji,
                        style: TextStyle(fontSize: 44.adaptSize),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.adaptSize,
                      vertical: 6.adaptSize,
                    ),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20.adaptSize),
                    ),
                    child: Text(
                      category.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.fSize,
                        fontWeight: FontWeight.bold,
                        color: category.color,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(28.adaptSize),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.adaptSize),
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
                          Icons.format_quote,
                          size: 32.adaptSize,
                          color: category.color.withOpacity(0.4),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          _currentQuestion ?? '',
                          style: TextStyle(
                            fontSize: 20.fSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2933),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Container(
                    padding: EdgeInsets.all(20.adaptSize),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16.adaptSize),
                      border: Border.all(
                        color: category.color.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.people,
                          color: category.color,
                          size: 24.adaptSize,
                        ),
                        SizedBox(width: 12.adaptSize),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.translate('discuss_together'),
                                style: TextStyle(
                                  fontSize: 14.fSize,
                                  fontWeight: FontWeight.w600,
                                  color: category.color,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '$_player1Name & $_player2Name',
                                style: TextStyle(
                                  fontSize: 13.fSize,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    l10n.translate('answer_out_loud'),
                    style: TextStyle(
                      fontSize: 13.fSize,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(20.adaptSize),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _nextSpin,
                icon: Icon(
                  _roundsPlayed >= _maxRounds - 1
                      ? Icons.visibility
                      : Icons.rotate_right,
                  color: Colors.white,
                ),
                label: Text(
                  _roundsPlayed >= _maxRounds - 1
                      ? l10n.translate('view_summary')
                      : l10n.translate('next_spin'),
                  style: TextStyle(fontSize: 18.fSize, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: category.color,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.adaptSize),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryScreen(AppLocalizations l10n, Color defaultColor) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: defaultColor,
        title: Text(l10n.translate('session_summary')),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              24.adaptSize,
              20.adaptSize,
              24.adaptSize,
              20.adaptSize,
            ),
            color: defaultColor.withOpacity(0.1),
            child: Column(
              children: [
                Icon(
                  Icons.auto_stories,
                  size: 48.adaptSize,
                  color: defaultColor,
                ),
                SizedBox(height: 8.h),
                Text(
                  l10n.translate('your_session'),
                  style: TextStyle(
                    fontSize: 24.fSize,
                    fontWeight: FontWeight.bold,
                    color: defaultColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$_player1Name & $_player2Name  |  $_maxRounds ${l10n.translate('spins')}',
                  style: TextStyle(
                    fontSize: 14.fSize,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.adaptSize),
              itemCount: _sessionHistory.length,
              itemBuilder: (context, index) {
                final entry = _sessionHistory[index];
                final cat = _categories.firstWhere(
                  (c) => c.id == entry.category,
                  orElse: () => _categories[0],
                );

                return Container(
                  margin: EdgeInsets.only(bottom: 12.adaptSize),
                  padding: EdgeInsets.all(16.adaptSize),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.adaptSize),
                    border: Border.all(color: cat.color.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40.adaptSize,
                        height: 40.adaptSize,
                        decoration: BoxDecoration(
                          color: cat.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12.adaptSize),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.spinNumber}',
                            style: TextStyle(
                              fontSize: 16.fSize,
                              fontWeight: FontWeight.bold,
                              color: cat.color,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.adaptSize),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${cat.emoji} ${cat.label}',
                              style: TextStyle(
                                fontSize: 12.fSize,
                                fontWeight: FontWeight.w600,
                                color: cat.color,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              entry.question,
                              style: TextStyle(
                                fontSize: 15.fSize,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1F2933),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16.adaptSize),
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _resetForNewSession,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: Text(
                      l10n.translate('spin_again_new_session'),
                      style: TextStyle(fontSize: 18.fSize, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: defaultColor,
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
                    onPressed: _finishGame,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.adaptSize),
                      ),
                    ),
                    child: Text(
                      l10n.translate('end_session'),
                      style: TextStyle(
                        fontSize: 16.fSize,
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

class _WheelPainter extends CustomPainter {
  final List<_CategoryData> categories;
  final int? selectedIndex;
  final Set<String> appearedCategories;
  final double rotationAngle;

  _WheelPainter({
    required this.categories,
    this.selectedIndex,
    this.appearedCategories = const {},
    this.rotationAngle = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final segmentAngle = (2 * pi) / categories.length;

    for (int i = 0; i < categories.length; i++) {
      final startAngle = i * segmentAngle - pi / 2 + rotationAngle;
      final cat = categories[i];
      final hasAppeared = appearedCategories.contains(cat.id);
      final isSelected = selectedIndex == i;

      final paint = Paint()
        ..color = hasAppeared
            ? cat.color.withOpacity(0.95)
            : cat.color.withOpacity(0.75)
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
      );
      path.close();
      canvas.drawPath(path, paint);

      // Highlight selected segment with thicker border + glow
      if (isSelected) {
        final glowPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        canvas.drawPath(path, glowPaint);
      }

      // Draw separator lines
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(isSelected ? 0 : 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(path, borderPaint);

      // Draw emoji
      final labelAngle = startAngle + segmentAngle / 2;
      final labelRadius = radius * 0.55;
      final labelX = center.dx + labelRadius * cos(labelAngle);
      final labelY = center.dy + labelRadius * sin(labelAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: cat.emoji,
          style: TextStyle(
            fontSize: isSelected ? 30 : 24,
            shadows: isSelected
                ? [Shadow(color: Colors.white54, blurRadius: 12)]
                : null,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
      );

      // Draw short label text
      final shortLabel = _shortLabel(cat.label);
      final labelTextPainter = TextPainter(
        text: TextSpan(
          text: shortLabel,
          style: TextStyle(
            fontSize: isSelected ? 11 : 9,
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelTextPainter.layout();
      labelTextPainter.paint(
        canvas,
        Offset(labelX - labelTextPainter.width / 2, labelY + 16),
      );
    }

    // Draw pointer triangle at ~35% from right side, rotated toward wheel center
    final pointerPaint = Paint()
      ..color = const Color(0xFFFF6B9D)
      ..style = PaintingStyle.fill;
    final pointerBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final double pointerOffset = radius * (-0.5);
    final double pointerY = center.dy - radius - (-5);
    final double angleToCenter = atan2(radius + 12, -pointerOffset);
    canvas.save();
    canvas.translate(center.dx + pointerOffset, pointerY);
    canvas.rotate(angleToCenter - pi / 2);
    final pathPointer = Path();
    pathPointer.moveTo(-18, -14);
    pathPointer.lineTo(18, -14);
    pathPointer.lineTo(0, 16);
    pathPointer.close();
    canvas.drawPath(pathPointer, pointerPaint);
    canvas.drawPath(pathPointer, pointerBorderPaint);
    canvas.restore();
    canvas.drawShadow(pathPointer, Colors.black54, 6, false);

    // Draw center circle
    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.1, centerPaint);
    final centerBorderPaint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius * 0.1, centerBorderPaint);
  }

  String _shortLabel(String label) {
    if (label == 'Emotional Connection') return 'Emotion';
    if (label == 'Shared Dreams') return 'Dreams';
    if (label == 'Conflict Resolution') return 'Conflict';
    if (label == 'Playful Memories') return 'Playful';
    if (label == 'Building the Future') return 'Future';
    if (label == 'Values & Principles') return 'Values';
    return label;
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) => true;
}
