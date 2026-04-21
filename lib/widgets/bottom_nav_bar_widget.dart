import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/screens/chat/chat_screen.dart';
import 'package:velmora/screens/game/gamescreen.dart';
import 'package:velmora/screens/home/home_screen.dart';
import 'package:velmora/screens/kegel/kegel_screen.dart';
import 'package:velmora/screens/settings/settings_screen.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:flutter/material.dart';

class BottomNavBarWidget extends StatefulWidget {
  const BottomNavBarWidget({super.key});

  @override
  State<BottomNavBarWidget> createState() => BottomNavBarWidgetState();
}

class BottomNavBarWidgetState extends State<BottomNavBarWidget> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        onNavigateToTab: (index) => setState(() => _currentIndex = index),
      ),
      GamesScreen(onBackToHome: () => setState(() => _currentIndex = 0)),
      KegelScreen(onBackToHome: () => setState(() => _currentIndex = 0)),
      ChatScreen(onBackToHome: () => setState(() => _currentIndex = 0)),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF8B42FF);
    const Color selectedBg = Color(0xFFF0E6FF);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: 75.h,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              0,
              Icons.home_filled,
              l10n.home,
              primaryPurple,
              selectedBg,
            ),
            _buildNavItem(
              1,
              Icons.sports_esports,
              l10n.games,
              primaryPurple,
              selectedBg,
            ),
            _buildNavItem(2, Icons.bolt, l10n.kegel, primaryPurple, selectedBg),
            _buildNavItem(
              3,
              Icons.chat_bubble_outline,
              l10n.chat,
              primaryPurple,
              selectedBg,
            ),
            _buildNavItem(
              4,
              Icons.settings_outlined,
              l10n.settings,
              primaryPurple,
              selectedBg,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    Color selectedColor,
    Color selectedBg,
  ) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12.adaptSize),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? selectedColor : Colors.grey,
                size: 24.adaptSize,
              ),
              SizedBox(height: 3.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.fSize,
                  color: isSelected ? selectedColor : Colors.grey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
