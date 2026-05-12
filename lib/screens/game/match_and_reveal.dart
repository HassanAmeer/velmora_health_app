import 'package:flutter/material.dart';
import 'package:velmora/services/game_service.dart';
import 'package:velmora/services/game_questions_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/widgets/game_progress_indicator.dart';
import 'package:velmora/widgets/skeletons/game_skeleton.dart';
import 'package:velmora/models/game_question.dart';
import 'package:velmora/services/vibration_service.dart';

class MatchAndRevealScreen extends StatefulWidget {
  const MatchAndRevealScreen({super.key});

  @override
  State<MatchAndRevealScreen> createState() => _MatchAndRevealScreenState();
}

enum VoteValue { yes, maybe, no }

enum _GamePhase { nameEntry, handoff, partnerAVoting, partnerBTransition, partnerBVoting, reveal, completed }

class _MatchAndRevealScreenState extends State<MatchAndRevealScreen> {
  final GameService _gameService = GameService();
  final GameQuestionsService _questionsService = GameQuestionsService();
  final TextEditingController _player1Controller = TextEditingController();
  final TextEditingController _player2Controller = TextEditingController();

  List<GameQuestion> _cards = [];
  int _currentCardIndex = 0;
  String? _sessionId;
  bool _isLoading = true;

  String _player1Name = 'Partner A';
  String _player2Name = 'Partner B';
  _GamePhase _phase = _GamePhase.nameEntry;

  final Map<int, VoteValue> _partnerAVotes = {};
  final Map<int, VoteValue> _partnerBVotes = {};
  bool _showFullHistory = false;
  bool _showDimOverlay = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      _sessionId = await _gameService.startGameSessionById('match_and_reveal');
      final cards = await _questionsService.generateMatchAndRevealCards();
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterNames)),
      );
      return;
    }
    setState(() {
      _player1Name = _player1Controller.text.trim();
      _player2Name = _player2Controller.text.trim();
      _phase = _GamePhase.handoff;
      _currentCardIndex = 0;
    });
    VibrationService.doubleVibration();
  }

  void _castVote(VoteValue vote) {
    if (_phase == _GamePhase.partnerAVoting) {
      _partnerAVotes[_currentCardIndex] = vote;
    } else {
      _partnerBVotes[_currentCardIndex] = vote;
    }
    VibrationService.lightVibration();
    setState(() => _showDimOverlay = true);

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _showDimOverlay = false);

      if (_currentCardIndex < _cards.length - 1) {
        setState(() => _currentCardIndex++);
      } else if (_phase == _GamePhase.partnerAVoting) {
        setState(() {
          _phase = _GamePhase.partnerBTransition;
          _currentCardIndex = 0;
        });
      } else {
        _showMatchResults();
      }
    });
  }

  void _confirmHandoff() {
    setState(() {
      _phase = _GamePhase.partnerAVoting;
      _currentCardIndex = 0;
    });
    VibrationService.doubleVibration();
  }

  void _startPartnerBTurn() {
    setState(() {
      _phase = _GamePhase.partnerBVoting;
      _currentCardIndex = 0;
    });
    VibrationService.doubleVibration();
  }

  void _showMatchResults() {
    setState(() {
      _phase = _GamePhase.reveal;
    });
    VibrationService.longVibration();
  }

  List<Map<String, dynamic>> _getMatches() {
    final matches = <Map<String, dynamic>>[];
    for (int i = 0; i < _cards.length; i++) {
      final aVote = _partnerAVotes[i];
      final bVote = _partnerBVotes[i];
      if (aVote != null && bVote != null && aVote != VoteValue.no && bVote != VoteValue.no) {
        matches.add({
          'card': _cards[i],
          'aVote': aVote,
          'bVote': bVote,
        });
      }
    }
    return matches;
  }

  List<Map<String, dynamic>> _getAllCardsWithVotes() {
    final all = <Map<String, dynamic>>[];
    for (int i = 0; i < _cards.length; i++) {
      all.add({
        'card': _cards[i],
        'aVote': _partnerAVotes[i],
        'bVote': _partnerBVotes[i],
        'isMatch': _partnerAVotes[i] != null && _partnerBVotes[i] != null &&
            _partnerAVotes[i] != VoteValue.no && _partnerBVotes[i] != VoteValue.no,
      });
    }
    return all;
  }

  int _getMatchCount() => _getMatches().length;

  Future<void> _completeGame() async {
    try {
      if (_sessionId != null) {
        await _gameService.completeGameSession(_sessionId!);
      }
      setState(() => _phase = _GamePhase.completed);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorCompletingGame)),
        );
      }
    }
  }

  void _playAgain() {
    setState(() {
      _isLoading = true;
      _currentCardIndex = 0;
      _phase = _GamePhase.handoff;
      _partnerAVotes.clear();
      _partnerBVotes.clear();
      _showFullHistory = false;
    });
    _questionsService.generateMatchAndRevealCards().then((cards) {
      if (mounted) {
        setState(() {
          _cards = cards;
          _isLoading = false;
        });
      }
    });
    VibrationService.doubleVibration();
  }

  Color _getCardColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'soft': return const Color(0xFF4CAF50);
      case 'adventurous': return const Color(0xFFFF9800);
      case 'deep': return const Color(0xFFE91E63);
      default: return const Color(0xFF8B42FF);
    }
  }

  IconData _getVoteIcon(VoteValue vote) {
    switch (vote) {
      case VoteValue.yes: return Icons.favorite;
      case VoteValue.maybe: return Icons.touch_app;
      case VoteValue.no: return Icons.close;
    }
  }

  Color _getVoteColor(VoteValue vote) {
    switch (vote) {
      case VoteValue.yes: return const Color(0xFF4CAF50);
      case VoteValue.maybe: return const Color(0xFFFF9800);
      case VoteValue.no: return Colors.grey;
    }
  }

  String _voteLabel(VoteValue vote) {
    switch (vote) {
      case VoteValue.yes: return 'Yes';
      case VoteValue.maybe: return 'Maybe';
      case VoteValue.no: return 'No';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color primaryColor = Color(0xFFFF6B9D);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(l10n.translate('match_and_reveal')),
          elevation: 0,
        ),
        body: const GameScreenSkeleton(),
      );
    }

    if (_cards.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9FF),
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(l10n.translate('match_and_reveal')),
          elevation: 0,
        ),
        body: Center(child: Text(l10n.translate('no_prompts_available'))),
      );
    }

    switch (_phase) {
      case _GamePhase.nameEntry:
        return _buildNameScreen(l10n, primaryColor);
      case _GamePhase.handoff:
        return _buildHandoffScreen(l10n, primaryColor);
      case _GamePhase.partnerAVoting:
        return _buildVotingScreen(l10n, primaryColor, true);
      case _GamePhase.partnerBTransition:
        return _buildPartnerBTransition(l10n, primaryColor);
      case _GamePhase.partnerBVoting:
        return _buildVotingScreen(l10n, primaryColor, false);
      case _GamePhase.reveal:
        return _buildRevealScreen(l10n, primaryColor);
      case _GamePhase.completed:
        return _buildCompletionScreen(l10n, primaryColor);
    }
  }

  Widget _buildNameScreen(AppLocalizations l10n, Color primaryColor) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(l10n.translate('match_and_reveal')),
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
              style: TextStyle(fontSize: 28.fSize, fontWeight: FontWeight.bold, color: const Color(0xFF1F2933)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.translate('vote_privately'),
              style: TextStyle(fontSize: 14.fSize, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.h),
            TextField(
              controller: _player1Controller,
              decoration: InputDecoration(
                labelText: l10n.player1Name,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.adaptSize)),
                filled: true, fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _player2Controller,
              decoration: InputDecoration(
                labelText: l10n.player2Name,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.adaptSize)),
                filled: true, fillColor: Colors.white,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.adaptSize)),
                ),
                child: Text(l10n.startGame, style: TextStyle(fontSize: 18.fSize, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isPartnerATurn => _phase == _GamePhase.partnerAVoting;
  String get _currentVoterName => _isPartnerATurn ? _player1Name : _player2Name;

  Widget _buildHandoffScreen(AppLocalizations l10n, Color primaryColor) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(l10n.translate('match_and_reveal')),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.adaptSize),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pan_tool_alt, size: 80.adaptSize, color: primaryColor),
              SizedBox(height: 24.h),
              Text(
                l10n.translate('hand_phone_to_partner'),
                style: TextStyle(fontSize: 22.fSize, fontWeight: FontWeight.bold, color: const Color(0xFF1F2933)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                '$_player1Name ${l10n.translate('hand_phone_instruction')} $_player2Name',
                style: TextStyle(fontSize: 16.fSize, color: Colors.grey.shade600, height: 1.4),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                l10n.translate('partner_look_away'),
                style: TextStyle(fontSize: 14.fSize, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmHandoff,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.adaptSize)),
                  ),
                  child: Text(
                    l10n.translate('im_ready'),
                    style: TextStyle(fontSize: 18.fSize, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVotingScreen(AppLocalizations l10n, Color primaryColor, bool isPartnerA) {
    final currentCard = _cards[_currentCardIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(l10n.translate('match_and_reveal')),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              GameProgressIndicator(
                gameId: 'match_and_reveal',
                current: _currentCardIndex + 1,
                total: _cards.length,
                color: primaryColor,
                label: '${l10n.translate('card')} ${_currentCardIndex + 1} ${l10n.ofLabel} ${_cards.length}',
                trailingWidget: Text(
                  '$_currentVoterName\'s ${l10n.translate('turn')}',
                  style: TextStyle(fontSize: 13.fSize, color: primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.adaptSize),
                child: Text(
                  '$_currentVoterName: ${l10n.translate('vote_privately')}',
                  style: TextStyle(fontSize: 14.fSize, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.adaptSize),
                  child: Column(
                    children: [
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(28.adaptSize),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.adaptSize),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.adaptSize, vertical: 6.adaptSize),
                              decoration: BoxDecoration(
                                color: _getCardColor(currentCard.category).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20.adaptSize),
                              ),
                              child: Text(
                                currentCard.category?.toUpperCase() ?? l10n.translate('activity'),
                                style: TextStyle(
                                  fontSize: 12.fSize, fontWeight: FontWeight.bold,
                                  color: _getCardColor(currentCard.category), letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Text(
                              currentCard.getLocalizedQuestion(Localizations.localeOf(context).languageCode),
                              style: TextStyle(fontSize: 20.fSize, fontWeight: FontWeight.bold, color: const Color(0xFF1F2933), height: 1.3),
                              textAlign: TextAlign.center,
                            ),
                            if (currentCard.description != null) ...[
                              SizedBox(height: 16.h),
                              Text(
                                currentCard.getLocalizedDescription(Localizations.localeOf(context).languageCode) ?? '',
                                style: TextStyle(fontSize: 15.fSize, color: Colors.grey.shade600, height: 1.4),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(20.adaptSize),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(child: _buildVoteButton(l10n.translate('no'), Icons.close, Colors.grey, VoteValue.no)),
                    SizedBox(width: 12.adaptSize),
                    Expanded(child: _buildVoteButton(l10n.translate('maybe'), Icons.touch_app, const Color(0xFFFF9800), VoteValue.maybe)),
                    SizedBox(width: 12.adaptSize),
                    Expanded(child: _buildVoteButton(l10n.translate('yes'), Icons.favorite, const Color(0xFF4CAF50), VoteValue.yes)),
                  ],
                ),
              ),
            ],
          ),
          if (_showDimOverlay)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showDimOverlay ? 1.0 : 0.0,
              child: Container(color: Colors.black54),
            ),
        ],
      ),
    );
  }

  Widget _buildVoteButton(String label, IconData icon, Color color, VoteValue vote) {
    return SizedBox(
      height: 56.h,
      child: ElevatedButton.icon(
        onPressed: () => _castVote(vote),
        icon: Icon(icon, color: Colors.white, size: 20.adaptSize),
        label: Text(label, style: TextStyle(fontSize: 15.fSize, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.adaptSize)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildPartnerBTransition(AppLocalizations l10n, Color primaryColor) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(l10n.translate('match_and_reveal')),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.adaptSize),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swap_horiz, size: 100.adaptSize, color: primaryColor),
              SizedBox(height: 32.h),
              Text(
                '$_player1Name ${l10n.translate('done_voting')}',
                style: TextStyle(fontSize: 22.fSize, fontWeight: FontWeight.bold, color: const Color(0xFF1F2933)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                l10n.translate('now_its').replaceAll('{name}', _player2Name),
                style: TextStyle(fontSize: 18.fSize, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                l10n.translate('hand_phone_to_partner'),
                style: TextStyle(fontSize: 14.fSize, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startPartnerBTurn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.adaptSize)),
                  ),
                  child: Text(
                    l10n.translate('start_partner_turn'),
                    style: TextStyle(fontSize: 18.fSize, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevealScreen(AppLocalizations l10n, Color primaryColor) {
    final matches = _getMatches();
    final allCards = _getAllCardsWithVotes();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(l10n.translate('your_matches')),
        elevation: 0,
      ),
      body: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(24.adaptSize, 20.adaptSize, 24.adaptSize, 16.adaptSize),
                  color: primaryColor.withOpacity(0.1),
                  child: Column(
                    children: [
                      Icon(Icons.celebration, size: 48.adaptSize, color: primaryColor),
                      SizedBox(height: 8.h),
                      Text(
                        l10n.translate('your_matches'),
                        style: TextStyle(fontSize: 24.fSize, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${matches.length} / ${_cards.length} ${l10n.translate('matches_found')}',
                        style: TextStyle(fontSize: 18.fSize, color: primaryColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.adaptSize, vertical: 12.h),
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleChip(
                    label: 'Matches (${matches.length})',
                    selected: !_showFullHistory,
                    color: primaryColor,
                    onTap: () => setState(() => _showFullHistory = false),
                  ),
                ),
                SizedBox(width: 12.adaptSize),
                Expanded(
                  child: _buildToggleChip(
                    label: 'All Cards (${_cards.length})',
                    selected: _showFullHistory,
                    color: Colors.grey,
                    onTap: () => setState(() => _showFullHistory = true),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _showFullHistory
                ? ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20.adaptSize),
                    itemCount: allCards.length,
                    itemBuilder: (context, index) => _buildFullHistoryCard(l10n, allCards[index], primaryColor, index),
                  )
                : matches.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.adaptSize),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 80.adaptSize, color: Colors.grey.shade400),
                              SizedBox(height: 16.h),
                              Text(l10n.translate('no_matches_yet'),
                                style: TextStyle(fontSize: 20.fSize, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20.adaptSize),
                        itemCount: matches.length,
                        itemBuilder: (context, index) => _buildMatchCard(l10n, matches[index], primaryColor),
                      ),
          ),
          Container(
            padding: EdgeInsets.all(20.adaptSize),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _completeGame,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: Text(l10n.translate('done_exploring'), style: TextStyle(fontSize: 18.fSize, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.adaptSize)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip({required String label, required bool selected, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.adaptSize),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.fSize,
              fontWeight: FontWeight.w600,
              color: selected ? color : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(AppLocalizations l10n, Map<String, dynamic> match, Color primaryColor) {
    final card = match['card'] as GameQuestion;
    final aVote = match['aVote'] as VoteValue;
    final bVote = match['bVote'] as VoteValue;
    final cardColor = _getCardColor(card.category);

    return Container(
      margin: EdgeInsets.only(bottom: 16.adaptSize),
      padding: EdgeInsets.all(20.adaptSize),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.adaptSize),
        border: Border.all(color: cardColor.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.adaptSize, vertical: 4.adaptSize),
                decoration: BoxDecoration(color: cardColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12.adaptSize)),
                child: Text(card.category?.toUpperCase() ?? '',
                  style: TextStyle(fontSize: 11.fSize, fontWeight: FontWeight.bold, color: cardColor)),
              ),
              const Spacer(),
              Icon(Icons.favorite, color: primaryColor, size: 18.adaptSize),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            card.getLocalizedQuestion(Localizations.localeOf(context).languageCode),
            style: TextStyle(fontSize: 16.fSize, fontWeight: FontWeight.w600, color: const Color(0xFF1F2933)),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _buildVoteChip(_player1Name, aVote),
              SizedBox(width: 8.adaptSize),
              _buildVoteChip(_player2Name, bVote),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullHistoryCard(AppLocalizations l10n, Map<String, dynamic> item, Color primaryColor, int index) {
    final card = item['card'] as GameQuestion;
    final aVote = item['aVote'] as VoteValue?;
    final bVote = item['bVote'] as VoteValue?;
    final isMatch = item['isMatch'] as bool;
    final cardColor = _getCardColor(card.category);

    return Container(
      margin: EdgeInsets.only(bottom: 12.adaptSize),
      padding: EdgeInsets.all(16.adaptSize),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.adaptSize),
        border: Border.all(color: isMatch ? primaryColor.withOpacity(0.3) : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.adaptSize, vertical: 2.adaptSize),
                decoration: BoxDecoration(color: cardColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8.adaptSize)),
                child: Text('#${index + 1}', style: TextStyle(fontSize: 10.fSize, fontWeight: FontWeight.bold, color: cardColor)),
              ),
              SizedBox(width: 8.adaptSize),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.adaptSize, vertical: 2.adaptSize),
                decoration: BoxDecoration(
                  color: isMatch ? primaryColor.withOpacity(0.12) : Colors.grey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.adaptSize),
                ),
                child: Text(
                  isMatch ? 'Match' : 'No Match',
                  style: TextStyle(fontSize: 10.fSize, fontWeight: FontWeight.bold, color: isMatch ? primaryColor : Colors.grey),
                ),
              ),
              if (card.category != null) ...[
                SizedBox(width: 8.adaptSize),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.adaptSize, vertical: 2.adaptSize),
                  decoration: BoxDecoration(color: cardColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8.adaptSize)),
                  child: Text(card.category!.toUpperCase(),
                    style: TextStyle(fontSize: 9.fSize, fontWeight: FontWeight.bold, color: cardColor)),
                ),
              ],
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            card.getLocalizedQuestion(Localizations.localeOf(context).languageCode),
            style: TextStyle(fontSize: 14.fSize, fontWeight: FontWeight.w500, color: const Color(0xFF1F2933)),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              _buildMiniVoteChip(_player1Name, aVote),
              SizedBox(width: 12.adaptSize),
              _buildMiniVoteChip(_player2Name, bVote),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoteChip(String name, VoteValue vote) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.adaptSize, vertical: 4.adaptSize),
      decoration: BoxDecoration(color: _getVoteColor(vote).withOpacity(0.15), borderRadius: BorderRadius.circular(12.adaptSize)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getVoteIcon(vote), size: 14.adaptSize, color: _getVoteColor(vote)),
          SizedBox(width: 4.adaptSize),
          Text(name, style: TextStyle(fontSize: 12.fSize, color: _getVoteColor(vote), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMiniVoteChip(String name, VoteValue? vote) {
    if (vote == null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.adaptSize, vertical: 3.adaptSize),
        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8.adaptSize)),
        child: Text('$name: —', style: TextStyle(fontSize: 11.fSize, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.adaptSize, vertical: 3.adaptSize),
      decoration: BoxDecoration(color: _getVoteColor(vote).withOpacity(0.12), borderRadius: BorderRadius.circular(8.adaptSize)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getVoteIcon(vote), size: 12.adaptSize, color: _getVoteColor(vote)),
          SizedBox(width: 3.adaptSize),
          Text('$name: ${_voteLabel(vote)}',
            style: TextStyle(fontSize: 11.fSize, color: _getVoteColor(vote), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen(AppLocalizations l10n, Color primaryColor) {
    final matchCount = _getMatchCount();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(l10n.translate('match_and_reveal')),
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
              l10n.translate('great_exploring'),
              style: TextStyle(fontSize: 32.fSize, fontWeight: FontWeight.bold, color: const Color(0xFF1F2933)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.adaptSize, vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.adaptSize),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: Column(
                children: [
                  _buildStatRow(Icons.credit_card, '${_cards.length} Cards Explored', Colors.grey.shade700),
                  SizedBox(height: 10.h),
                  _buildStatRow(Icons.favorite, '$matchCount Matches Found', primaryColor),
                  SizedBox(height: 10.h),
                  _buildStatRow(Icons.people, '$_player1Name & $_player2Name', Colors.grey.shade700),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _playAgain,
                icon: const Icon(Icons.replay, color: Colors.white),
                label: Text(l10n.playAgain, style: TextStyle(fontSize: 18.fSize, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.adaptSize)),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.adaptSize)),
                ),
                child: Text(l10n.backToGames, style: TextStyle(fontSize: 16.fSize, color: Colors.grey.shade600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String text, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20.adaptSize, color: color),
        SizedBox(width: 10.adaptSize),
        Text(text, style: TextStyle(fontSize: 16.fSize, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
