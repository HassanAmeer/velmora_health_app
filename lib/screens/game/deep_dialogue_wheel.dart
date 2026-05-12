import 'dart:math';
import 'package:flutter/material.dart';
import 'package:velmora/services/game_service.dart';
import 'package:velmora/services/game_questions_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/widgets/game_progress_indicator.dart';
import 'package:velmora/widgets/skeletons/game_skeleton.dart';
import 'package:velmora/models/game_question.dart';
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
  final IconData icon;
  final Color color;

  const _CategoryData({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const Map<String, String> _categoryEmojis = {
  'emotional_connection': '\u2764\uFE0F',
  'future_dreams': '\u2B50',
  'conflict_resolution': '\uD83E\uDD1D',
  'playful_memories': '\uD83C\uDF89',
  'gratitude': '\uD83D\uDE4F',
  'adventure': '\uD83D\uDE80',
};

const List<_CategoryData> _categories = [
  _CategoryData(
    id: 'emotional_connection',
    label: 'Emotional Connection',
    icon: Icons.favorite,
    color: Color(0xFFE91E63),
  ),
  _CategoryData(
    id: 'future_dreams',
    label: 'Future Dreams',
    icon: Icons.star,
    color: Color(0xFF9C27B0),
  ),
  _CategoryData(
    id: 'conflict_resolution',
    label: 'Conflict Resolution',
    icon: Icons.chat_bubble_outline,
    color: Color(0xFFFF9800),
  ),
  _CategoryData(
    id: 'playful_memories',
    label: 'Playful Memories',
    icon: Icons.celebration,
    color: Color(0xFF4CAF50),
  ),
  _CategoryData(
    id: 'gratitude',
    label: 'Gratitude',
    icon: Icons.favorite_border,
    color: Color(0xFF2196F3),
  ),
  _CategoryData(
    id: 'adventure',
    label: 'Adventure',
    icon: Icons.explore,
    color: Color(0xFF00BCD4),
  ),
];

class _DeepDialogueWheelScreenState extends State<DeepDialogueWheelScreen>
    with SingleTickerProviderStateMixin {
  final GameService _gameService = GameService();
  final GameQuestionsService _questionsService = GameQuestionsService();
  final TextEditingController _player1Controller = TextEditingController();
  final TextEditingController _player2Controller = TextEditingController();

  List<GameQuestion> _questions = [];
  String? _sessionId;
  bool _isLoading = true;
  bool _gameCompleted = false;

  String _player1Name = 'Partner A';
  String _player2Name = 'Partner B';
  bool _namesSet = false;

  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  double _currentAngle = 0;
  bool _isSpinning = false;
  int? _selectedCategoryIndex;
  GameQuestion? _currentQuestion;
  int _roundsPlayed = 0;
  static const int _maxRounds = 6;
  String? _lastCategory;

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
      _sessionId =
          await _gameService.startGameSessionById('deep_dialogue_wheel');
      final questions =
          await _questionsService.getQuestions('deep_dialogue_wheel');
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

  void _onSpinUpdate() {
    setState(() {
      _currentAngle = _spinAnimation.value * 2 * pi * 5;
    });
  }

  void _onSpinStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _isSpinning = false;
        _selectedCategoryIndex = _determineCategory();
        _currentQuestion = _getQuestionForCategory(
          _categories[_selectedCategoryIndex!].id,
        );
      });
      VibrationService.longVibration();
    }
  }

  int _determineCategory() {
    final finalAngle = _currentAngle % (2 * pi);
    final segmentAngle = (2 * pi) / _categories.length;
    int index = (finalAngle / segmentAngle).floor();
    if (index >= _categories.length) index = 0;

    if (_categories[index].id == _lastCategory) {
      index = (index + 1) % _categories.length;
    }
    _lastCategory = _categories[index].id;
    return index;
  }

  GameQuestion? _getQuestionForCategory(String categoryId) {
    final catQuestions = _questions
        .where((q) => q.category?.toLowerCase() == categoryId.toLowerCase())
        .toList();
    if (catQuestions.isEmpty) return null;
    final random = Random();
    return catQuestions[random.nextInt(catQuestions.length)];
  }

  void _spin() {
    if (_isSpinning || _roundsPlayed >= _maxRounds) return;
    setState(() {
      _isSpinning = true;
      _currentQuestion = null;
      _selectedCategoryIndex = null;
    });
    VibrationService.doubleVibration();
    _spinController.forward(from: 0);
  }

  void _nextRound() {
    if (_roundsPlayed >= _maxRounds - 1) {
      _finishGame();
      return;
    }
    setState(() {
      _roundsPlayed++;
      _currentQuestion = null;
      _selectedCategoryIndex = null;
      _currentAngle = 0;
    });
    VibrationService.lightVibration();
  }

  Future<void> _finishGame() async {
    try {
      if (_sessionId != null) {
        await _gameService.completeGameSession(_sessionId!);
      }
      setState(() {
        _gameCompleted = true;
      });
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
    const Color primaryColor = Color(0xFF6C63FF);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(l10n.translate('deep_dialogue_wheel')),
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
          title: Text(l10n.translate('deep_dialogue_wheel')),
          elevation: 0,
        ),
        body: Center(child: Text(l10n.translate('no_prompts_available'))),
      );
    }

    if (!_namesSet) {
      return _buildNameScreen(l10n, primaryColor);
    }

    if (_gameCompleted) {
      return _buildCompletionScreen(l10n, primaryColor);
    }

    if (_currentQuestion != null && _selectedCategoryIndex != null) {
      return _buildQuestionScreen(l10n, primaryColor);
    }

    return _buildWheelScreen(l10n, primaryColor);
  }

  Widget _buildNameScreen(AppLocalizations l10n, Color primaryColor) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(l10n.translate('deep_dialogue_wheel')),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(24.adaptSize),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 80.adaptSize, color: primaryColor),
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

  Widget _buildCompletionScreen(AppLocalizations l10n, Color primaryColor) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(l10n.translate('deep_dialogue_wheel')),
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
              l10n
                  .translate('you_had_rounds')
                  .replaceAll('{count}', _roundsPlayed.toString()),
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

  Widget _buildWheelScreen(AppLocalizations l10n, Color primaryColor) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(l10n.translate('deep_dialogue_wheel')),
        elevation: 0,
      ),
      body: Column(
        children: [
          GameProgressIndicator(
            gameId: 'deep_dialogue_wheel',
            current: _roundsPlayed + 1,
            total: _maxRounds,
            color: primaryColor,
            label:
                '${l10n.translate('round')} ${_roundsPlayed + 1} ${l10n.ofLabel} $_maxRounds',
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
                          return Transform.rotate(
                            angle: _currentAngle,
                            child: child,
                          );
                        },
                        child: CustomPaint(
                          size: Size(300.adaptSize, 300.adaptSize),
                          painter: _WheelPainter(
                            categories: _categories,
                            selectedIndex: _selectedCategoryIndex,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _isSpinning
                        ? l10n.translate('spinning')
                        : l10n.translate('tap_to_spin'),
                    style: TextStyle(
                      fontSize: 16.fSize,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '${_roundsPlayed}/$_maxRounds ${l10n.translate('rounds')}',
                    style: TextStyle(
                      fontSize: 14.fSize,
                      color: Colors.grey.shade400,
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
                      : l10n.translate('spin_the_wheel'),
                  style: TextStyle(
                    fontSize: 18.fSize,
                    color: _isSpinning ? Colors.grey : Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isSpinning ? Colors.grey.shade300 : primaryColor,
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

  Widget _buildQuestionScreen(AppLocalizations l10n, Color primaryColor) {
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
                '${l10n.translate('round')} ${_roundsPlayed + 1} ${l10n.ofLabel} $_maxRounds',
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
                    child: Icon(
                      category.icon,
                      size: 48.adaptSize,
                      color: category.color,
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
                    child: Text(
                      _currentQuestion!.getLocalizedQuestion(
                        Localizations.localeOf(context).languageCode,
                      ),
                      style: TextStyle(
                        fontSize: 20.fSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2933),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
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
                onPressed: _nextRound,
                icon: Icon(
                  _roundsPlayed >= _maxRounds - 1
                      ? Icons.check_circle
                      : Icons.rotate_right,
                  color: Colors.white,
                ),
                label: Text(
                  _roundsPlayed >= _maxRounds - 1
                      ? l10n.translate('finish')
                      : l10n.translate('next_round'),
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
}

class _WheelPainter extends CustomPainter {
  final List<_CategoryData> categories;
  final int? selectedIndex;

  _WheelPainter({required this.categories, this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final segmentAngle = (2 * pi) / categories.length;

    for (int i = 0; i < categories.length; i++) {
      final startAngle = i * segmentAngle - pi / 2;

      final paint = Paint()
        ..color = categories[i].color.withOpacity(0.85)
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

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(path, borderPaint);

      // Draw emoji label
      final labelAngle = startAngle + segmentAngle / 2;
      final labelRadius = radius * 0.6;
      final labelX = center.dx + labelRadius * cos(labelAngle);
      final labelY = center.dy + labelRadius * sin(labelAngle);

      final emoji = _categoryEmojis[categories[i].id] ?? '\u2764\uFE0F';
      final textPainter = TextPainter(
        text: TextSpan(
          text: emoji,
          style: TextStyle(
            fontSize: 26,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
      );
    }

    // Draw center circle
    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.12, centerPaint);
    final centerBorderPaint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius * 0.12, centerBorderPaint);
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) => true;
}


