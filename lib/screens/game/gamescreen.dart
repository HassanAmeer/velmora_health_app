import 'package:velmora/screens/settings/subscription_screen.dart';
import 'package:velmora/services/subscription_service.dart';
import 'package:velmora/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:velmora/services/game_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/screens/game/truth_or_truth_game.dart';
import 'package:velmora/screens/game/love_language_quiz.dart';
import 'package:velmora/screens/game/reflection_game.dart';
import 'package:velmora/screens/game/couples_challenge.dart';
import 'package:velmora/screens/game/would_you_rather.dart';
import 'package:velmora/screens/game/date_night_ideas.dart';
import 'package:velmora/screens/game/relationship_quiz.dart';
import 'package:velmora/screens/game/compliment_game.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velmora/widgets/skeletons/games_skeleton.dart';

class GamesScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const GamesScreen({super.key, this.onBackToHome});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final GameService _gameService = GameService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _games = [];
  Map<String, dynamic>? _userProgress;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get default games with all details
      List<Map<String, dynamic>> loadedGames = _getDefaultGames();

      // Load Firestore data for isPremium and isActive status
      try {
        final gamesSnapshot = await _firestore.collection('games').get();

        // Update games with Firestore data
        for (var doc in gamesSnapshot.docs) {
          final firestoreData = doc.data();
          final gameIndex = loadedGames.indexWhere((g) => g['id'] == doc.id);

          if (gameIndex != -1) {
            loadedGames[gameIndex]['isPremium'] =
                firestoreData['isPremium'] ??
                loadedGames[gameIndex]['isPremium'];
            loadedGames[gameIndex]['isActive'] =
                firestoreData['isActive'] ?? true;
          }
        }

        // Filter out inactive games
        loadedGames = loadedGames
            .where((game) => game['isActive'] == true)
            .toList();
      } catch (e) {
        // If Firestore fails, use default values from _getDefaultGames
        print('Error loading game settings from Firestore: $e');
      }

      // Load user progress
      final progress = await _gameService.getUserGameProgress();

      if (!mounted) return;

      setState(() {
        _games = loadedGames;
        _userProgress = progress;
        _isLoading = false;
      });
    } catch (e) {
      // If everything fails, use default games
      if (!mounted) return;

      setState(() {
        _games = _getDefaultGames();
        _isLoading = false;
      });

      // Still try to load progress
      try {
        final progress = await _gameService.getUserGameProgress();
        if (!mounted) return;

        setState(() {
          _userProgress = progress;
        });
      } catch (e) {
        // Ignore progress error
      }
    }
  }

  List<Map<String, dynamic>> _getDefaultGames() {
    return [
      {
        'id': 'truth_or_truth',
        'name': 'Truth or Truth',
        'description': 'Deep questions to spark meaningful conversations',
        'icon': 'favorite_border',
        'color': '#FF4D8D',
        'headerColor': '#FF4D8D',
        'players': '2 players',
        'time': '15 min',
        'isPremium': false,
        'screenType': 'truth_or_truth',
      },
      {
        'id': 'love_language_quiz',
        'name': 'Love Language Quiz',
        'description': 'Discover how you both give and receive love',
        'icon': 'people',
        'color': '#B388FF',
        'headerColor': '#B388FF',
        'players': '2 players',
        'time': '10 min',
        'isPremium': true,
        'screenType': 'quiz',
      },
      {
        'id': 'reflection_game',
        'name': 'Reflection & Discussion',
        'description': 'Deepen your connection through meaningful reflections',
        'icon': 'lightbulb_outline',
        'color': '#4CAF50',
        'headerColor': '#4CAF50',
        'players': '2 players',
        'time': '20 min',
        'isPremium': false,
        'screenType': 'reflection',
      },
      {
        'id': 'couples_challenge',
        'name': 'Couple\'s Challenge',
        'description': 'Fun challenges to strengthen your bond',
        'icon': 'celebration',
        'color': '#FF9800',
        'headerColor': '#FF9800',
        'players': '2 players',
        'time': '15 min',
        'isPremium': false,
        'screenType': 'couples_challenge',
      },
      {
        'id': 'would_you_rather',
        'name': 'Would You Rather',
        'description': 'Fun scenarios to explore preferences together',
        'icon': 'help_outline',
        'color': '#673AB7',
        'headerColor': '#673AB7',
        'players': '2 players',
        'time': '15 min',
        'isPremium': false,
        'screenType': 'would_you_rather',
      },
      {
        'id': 'date_night_ideas',
        'name': 'Date Night Ideas',
        'description': 'Discover new ways to spend quality time together',
        'icon': 'restaurant',
        'color': '#E91E63',
        'headerColor': '#E91E63',
        'players': '2 players',
        'time': '10 min',
        'isPremium': false,
        'screenType': 'date_night_ideas',
      },
      {
        'id': 'relationship_quiz',
        'name': 'Relationship Quiz',
        'description': 'Test how well you know each other',
        'icon': 'quiz',
        'color': '#00BCD4',
        'headerColor': '#00BCD4',
        'players': '2 players',
        'time': '15 min',
        'isPremium': false,
        'screenType': 'relationship_quiz',
      },
      {
        'id': 'compliment_game',
        'name': 'Compliment Game',
        'description': 'Share meaningful compliments with each other',
        'icon': 'card_giftcard',
        'color': '#9C27B0',
        'headerColor': '#9C27B0',
        'players': '2 players',
        'time': '10 min',
        'isPremium': false,
        'screenType': 'compliment_game',
      },
    ];
  }

  Future<void> _startGame(String gameId) async {
    try {
      // Find game data
      final gameData = _games.firstWhere(
        (game) => game['id'] == gameId,
        orElse: () => {},
      );

      if (gameData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).gameNotFound)),
          );
        }
        return;
      }

      // Check if game is premium and user has access
      if (gameData['isPremium'] == true) {
        final hasAccess =
            await SubscriptionService().hasActiveSubscription() ||
            await UserService().isTrialActive();

        if (!hasAccess && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PremiumScreen()),
          );
          return;
        }
      }

      // Navigate to specific game screen based on screenType
      final screenType = gameData['screenType'] ?? gameId;
      Widget gameScreen;

      switch (screenType) {
        case 'truth_or_truth':
          gameScreen = const TruthOrTruthGameScreen();
          break;
        case 'quiz':
          gameScreen = const LoveLanguageQuizScreen();
          break;
        case 'reflection':
          gameScreen = const ReflectionGameScreen();
          break;
        case 'couples_challenge':
          gameScreen = const CouplesChallengeScreen();
          break;
        case 'would_you_rather':
          gameScreen = const WouldYouRatherScreen();
          break;
        case 'date_night_ideas':
          gameScreen = const DateNightIdeasScreen();
          break;
        case 'relationship_quiz':
          gameScreen = const RelationshipQuizScreen();
          break;
        case 'compliment_game':
          gameScreen = const ComplimentGameScreen();
          break;
        default:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).gameComingSoon),
              ),
            );
          }
          return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => gameScreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).errorStartingGame}: $e',
            ),
          ),
        );
      }
    }
  }

  int _getTimesPlayed(String gameId) {
    if (_userProgress == null) return 0;

    final sessions = _userProgress!['sessions'] as List<dynamic>? ?? [];
    return sessions.where((s) {
      if (s is Map) return s['gameId'] == gameId;
      if (s is String) return s == gameId;
      return false;
    }).length;
  }

  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return const Color(0xFF8B42FF); // Default purple
    }
    try {
      // Remove # if present
      final hexColor = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return const Color(0xFF8B42FF); // Default purple
    }
  }

  IconData _parseIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.sports_esports;
    }

    // Map of icon names to IconData
    final iconMap = {
      'favorite_border': Icons.favorite_border,
      'favorite': Icons.favorite,
      'people': Icons.people,
      'quiz': Icons.quiz,
      'sports_esports': Icons.sports_esports,
      'psychology': Icons.psychology,
      'chat_bubble_outline': Icons.chat_bubble_outline,
      'emoji_emotions': Icons.emoji_emotions,
      'casino': Icons.casino,
      'extension': Icons.extension,
      'lightbulb_outline': Icons.lightbulb_outline,
      'celebration': Icons.celebration,
      'help_outline': Icons.help_outline,
      'restaurant': Icons.restaurant,
      'card_giftcard': Icons.card_giftcard,
    };

    return iconMap[iconName] ?? Icons.sports_esports;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const GamesScreenSkeleton();
    }
    return _buildGamesContent(context);
  }

  Widget _buildGamesContent(BuildContext context) {
    // Specific local colors for this screen's UI elements
    const Color headerPink = Color(0xFFE91E63);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 200.h,
            decoration: const BoxDecoration(
              color: headerPink,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            padding: EdgeInsets.fromLTRB(24.w, 60.h, 24.w, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (widget.onBackToHome != null) {
                      widget.onBackToHome!();
                      return;
                    }
                    Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24.adaptSize,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  AppLocalizations.of(context).couplesGames,
                  style: TextStyle(
                    fontSize: 32.fSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  AppLocalizations.of(context).playTogether,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16.fSize,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Game Cards
          Expanded(
            child: _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!),
                        ElevatedButton(
                          onPressed: _loadGames,
                          child: Text(AppLocalizations.of(context).retry),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadGames,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 24.h,
                      ),
                      children: [
                        // Dynamic games from Firestore
                        ..._games.map((game) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 24.h),
                            child: _buildGameCard(
                              gameId: game['id'],
                              title: AppLocalizations.of(
                                context,
                              ).translate(game['id']),
                              description: AppLocalizations.of(
                                context,
                              ).translate('${game['id']}_desc'),
                              players: game['players'],
                              time: game['time'],
                              headerColor: _parseColor(game['headerColor']),
                              icon: _parseIcon(game['icon']),
                              isPremium: game['isPremium'] ?? false,
                            ),
                          );
                        }),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard({
    required String gameId,
    required String title,
    required String description,
    required String players,
    required String time,
    required Color headerColor,
    required IconData icon,
    bool isPremium = false,
  }) {
    final timesPlayed = _getTimesPlayed(gameId);
    final hasPlayed = timesPlayed > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25.adaptSize),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header Image Area
          Container(
            height: 150.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(25.adaptSize),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(icon, color: Colors.white, size: 70.adaptSize),
                ),
                if (isPremium)
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.all(6.adaptSize),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8.adaptSize),
                      ),
                      child: Icon(
                        Icons.workspace_premium,
                        color: const Color(0xFFFFD700),
                        size: 20.adaptSize,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Card Details
          Padding(
            padding: EdgeInsets.all(20.adaptSize),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20.fSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2933),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14.fSize,
                    height: 1.4,
                  ),
                ),
                if (timesPlayed > 0) ...[
                  SizedBox(height: 8.h),
                  Text(
                    '${AppLocalizations.of(context).played} $timesPlayed ${timesPlayed == 1 ? AppLocalizations.of(context).time : AppLocalizations.of(context).times}',
                    style: TextStyle(
                      color: headerColor,
                      fontSize: 12.fSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                SizedBox(height: 20.h),

                // Bottom Info Row
                Row(
                  children: [
                    // Players Info
                    Flexible(
                      child: _buildIconLabel(Icons.people_outline, players),
                    ),
                    SizedBox(width: 16.w),
                    // Time Info
                    Flexible(
                      child: _buildIconLabel(Icons.timer_outlined, time),
                    ),

                    const Spacer(),

                    // Play Button
                    SizedBox(
                      height: 44.h,
                      child: ElevatedButton.icon(
                        onPressed: () => _startGame(gameId),
                        icon: Icon(Icons.play_arrow, size: 18.adaptSize),
                        label: Text(
                          hasPlayed
                              ? AppLocalizations.of(context).playAgain
                              : AppLocalizations.of(context).playNow,
                          style: TextStyle(
                            fontSize:
                                Localizations.localeOf(context).languageCode ==
                                    'fr'
                                ? 12.fSize
                                : 14.fSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B42FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.adaptSize),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconLabel(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18.adaptSize, color: Colors.grey.shade500),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13.fSize),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
