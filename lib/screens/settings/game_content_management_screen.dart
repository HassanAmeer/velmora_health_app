import 'package:velmora/constants/app_colors.dart';
import 'package:velmora/services/game_content_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:flutter/material.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/widgets/app_loading_widgets.dart';

class GameContentManagementScreen extends StatefulWidget {
  const GameContentManagementScreen({super.key});

  @override
  State<GameContentManagementScreen> createState() =>
      _GameContentManagementScreenState();
}

class _GameContentManagementScreenState
    extends State<GameContentManagementScreen> {
  final GameContentService _contentService = GameContentService();

  bool _isRefreshing = false;
  final Map<String, bool> _gameRefreshStatus = {};
  final Map<String, int> _gameVersions = {};
  final Map<String, bool> _hasNewContent = {};

  @override
  void initState() {
    super.initState();
    _loadContentStatus();
  }

  Future<void> _loadContentStatus() async {
    try {
      final games = ['truth_or_truth', 'love_language_quiz', 'reflection_game'];

      for (var gameId in games) {
        final version = await _contentService.getCurrentVersion(gameId);
        final needsRefresh = await _contentService.needsContentRefresh(gameId);
        final hasNew = await _contentService.hasNewContent(gameId);

        if (mounted) {
          setState(() {
            _gameVersions[gameId] = version;
            _gameRefreshStatus[gameId] = needsRefresh;
            _hasNewContent[gameId] = hasNew;
          });
        }
      }
    } catch (e) {
      print('Error loading content status: $e');
    }
  }

  Future<void> _refreshGame(String gameId, String gameName) async {
    setState(() => _isRefreshing = true);

    try {
      switch (gameId) {
        case 'truth_or_truth':
          await _contentService.refreshTruthOrTruthContent();
          break;
        case 'love_language_quiz':
          await _contentService.refreshLoveLanguageContent();
          break;
        case 'reflection_game':
          await _contentService.refreshReflectionContent();
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)
                  .translate('content_refreshed_successfully')
                  .replaceAll('{name}', gameName),
            ),
            backgroundColor: Colors.green,
          ),
        );
        await _loadContentStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).translate('error_refreshing_content')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _refreshAllGames() async {
    setState(() => _isRefreshing = true);

    try {
      await _contentService.refreshAllContent();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).translate('all_game_content_refreshed_successfully'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        await _loadContentStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).translate('error_refreshing_content')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final schedule = _contentService.getRefreshSchedule();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: AppColors.brandPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.translate('game_content'),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isRefreshing ? null : _refreshAllGames,
          ),
        ],
      ),
      body: _isRefreshing
          ? const AppPageSkeleton() // uses generic since this is an admin-only refresh screen
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildScheduleCard(schedule),
                  SizedBox(height: 24.h),
                  Text(
                    l10n.games,
                    style: TextStyle(
                      fontSize: 18.fSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildGameCard(
                    'truth_or_truth',
                    l10n.translate('truth_or_truth'),
                    l10n.translate('truth_or_truth_desc'),
                    Icons.favorite,
                    Colors.pink,
                  ),
                  _buildGameCard(
                    'love_language_quiz',
                    l10n.translate('love_language_quiz'),
                    l10n.translate('love_language_quiz_desc'),
                    Icons.psychology,
                    Colors.purple,
                  ),
                  _buildGameCard(
                    'reflection_game',
                    l10n.translate('reflection_discussion'),
                    l10n.translate('reflection_discussion_desc'),
                    Icons.chat_bubble,
                    Colors.blue,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.all(20.adaptSize),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.adaptSize),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.white, size: 24),
              SizedBox(width: 12.w),
              Text(
                l10n.translate('refresh_schedule'),
                style: TextStyle(
                  fontSize: 18.fSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildScheduleRow(
            l10n.translate('frequency'),
            schedule['frequency'].toString().toUpperCase(),
          ),
          SizedBox(height: 8.h),
          _buildScheduleRow(
            l10n.translate('next_refresh'),
            _formatDate(schedule['nextRefresh']),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.adaptSize),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.adaptSize),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    l10n.translate(
                      'content_refreshes_automatically_every_30_days_with_new_questions',
                    ),
                    style: TextStyle(fontSize: 12.fSize, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14.fSize, color: Colors.white70),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.fSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildGameCard(
    String gameId,
    String name,
    String description,
    IconData icon,
    Color color,
  ) {
    final l10n = AppLocalizations.of(context);
    final version = _gameVersions[gameId] ?? 1;
    final needsRefresh = _gameRefreshStatus[gameId] ?? false;
    final hasNew = _hasNewContent[gameId] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.adaptSize),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.adaptSize),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.adaptSize),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.adaptSize),
                ),
                child: Icon(icon, color: color, size: 24.adaptSize),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 16.fSize,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (hasNew)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12.adaptSize),
                            ),
                            child: Text(
                              l10n.translate('new'),
                              style: TextStyle(
                                fontSize: 10.fSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12.fSize,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _buildInfoChip(
                l10n.translate('version_n').replaceAll('{version}', '$version'),
                Icons.tag,
                Colors.blue,
              ),
              SizedBox(width: 8.w),
              if (needsRefresh)
                _buildInfoChip(
                  l10n.translate('refresh_available'),
                  Icons.update,
                  Colors.orange,
                ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isRefreshing
                  ? null
                  : () => _refreshGame(gameId, name),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.adaptSize),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              child: Text(
                l10n.translate('refresh_content'),
                style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.adaptSize),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14.adaptSize),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.fSize,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }
}
