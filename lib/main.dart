import 'dart:async';
import 'package:velmora/firebase_options.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/screens/auth/sign_in_screen.dart';
import 'package:velmora/widgets/bottom_nav_bar_widget.dart';
import 'package:velmora/screens/splash/splash_screen.dart';
import 'package:velmora/services/auth_service.dart';
import 'package:velmora/services/user_service.dart';
import 'package:velmora/services/analytics_service.dart';
import 'package:velmora/services/ai_service.dart';
import 'package:velmora/services/subscription_service.dart';
import 'package:velmora/services/ai_config_setup.dart';
import 'package:velmora/services/error_cache_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // ============================================================
  // GLOBAL ERROR HANDLERS - CATCH ALL UNCAUGHT ERRORS
  // ============================================================

  // Catch all Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    final error = details.exception;
    final stack = details.stack;
    final timestamp = DateTime.now().toIso8601String();
    print('❌ [FATAL FLUTTER ERROR] $timestamp');
    print('❌ [FATAL FLUTTER ERROR] Type: ${error.runtimeType}');
    print('❌ [FATAL FLUTTER ERROR] Error: $error');
    print('❌ [FATAL FLUTTER ERROR] Stack trace:');
    print('❌ [FATAL FLUTTER ERROR] $stack');
    print('❌ [FATAL FLUTTER ERROR] Library: ${details.library}');
    print('❌ [FATAL FLUTTER ERROR] Context: ${details.context}');
    print(
      '❌ [FATAL FLUTTER ERROR] ════════════════════════════════════════════',
    );

    // Store error using ErrorCacheService
    ErrorCacheService().storeError(
      'Flutter Error: $error',
      stack.toString(),
      location: 'Flutter: ${details.library}',
    );
  };

  // Catch all platform/Dart errors (prevents app crashes)
  PlatformDispatcher.instance.onError = (error, stack) {
    final timestamp = DateTime.now().toIso8601String();
    print('❌ [FATAL PLATFORM ERROR] $timestamp');
    print('❌ [FATAL PLATFORM ERROR] Type: ${error.runtimeType}');
    print('❌ [FATAL PLATFORM ERROR] Error: $error');
    print('❌ [FATAL PLATFORM ERROR] Stack trace:');
    print('❌ [FATAL PLATFORM ERROR] $stack');
    print(
      '❌ [FATAL PLATFORM ERROR] ════════════════════════════════════════════',
    );

    // Store error using ErrorCacheService
    ErrorCacheService().storeError(
      'Platform Error: $error',
      stack.toString(),
      location: 'Platform',
    );

    // Return true to prevent crash - let app continue running
    return true;
  };

  // Catch all async errors that would otherwise crash the app
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize services
      await AnalyticsService().initialize();
      await AIService().initialize();
      await SubscriptionService().initialize();

      // Auto-setup AI config if it doesn't exist
      final configExists = await AIConfigSetup.configExists();
      if (!configExists) {
        debugPrint('AI config not found, setting up defaults...');
        await AIConfigSetup.setupAIConfig(
          apiKey: 'AIzaSyA9tO6byX7lOSuY3WW105nlLpdtnVenIgo',
          // apiKey: 'REPLACE_WITH_REAL_KEY_IN_FIRESTORE',
        );
      }

      // Print any cached errors from previous runs
      _printCachedErrors();

      runApp(const MyApp());
    },
    (error, stack) {
      final timestamp = DateTime.now().toIso8601String();
      print('❌ [FATAL ZONE ERROR] $timestamp');
      print('❌ [FATAL ZONE ERROR] Type: ${error.runtimeType}');
      print('❌ [FATAL ZONE ERROR] Error: $error');
      print('❌ [FATAL ZONE ERROR] Stack trace:');
      print('❌ [FATAL ZONE ERROR] $stack');
      print(
        '❌ [FATAL ZONE ERROR] ════════════════════════════════════════════',
      );

      // Store error using ErrorCacheService
      ErrorCacheService().storeError(
        'Zone Error: $error',
        stack.toString(),
        location: 'Zone',
      );
    },
  );
}

// Helper to print cached errors from previous runs
Future<void> _printCachedErrors() async {
  try {
    await ErrorCacheService().printDiagnostics();
  } catch (e) {
    print('⚠️ [ERROR CACHE] Failed to print diagnostics: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.changeLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final AnalyticsService _analyticsService = AnalyticsService();
  Locale _locale = const Locale('en', '');
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  void changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  Future<void> _initApp() async {
    // Show splash for 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
    _loadUserLanguage();
    // Listen to language changes after a short delay to ensure user is loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _listenToLanguageChanges();
      }
    });
  }

  Future<void> _loadUserLanguage() async {
    try {
      // First try to load from SharedPreferences (fast, works offline)
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('preferred_language');
      if (savedLang != null && mounted) {
        setState(() {
          _locale = Locale(savedLang, '');
        });
      }

      // Then try Firebase for the most up-to-date preference
      final userData = await _userService.getUserData();
      if (userData != null && mounted) {
        final langCode = userData['preferredLanguage'] ?? savedLang ?? 'en';
        setState(() {
          _locale = Locale(langCode, '');
        });
        // Sync to SharedPreferences
        await prefs.setString('preferred_language', langCode);
      }
    } catch (e) {
      debugPrint('Error loading language: $e');
    }
  }

  void _listenToLanguageChanges() {
    _userService.userStream.listen(
      (snapshot) {
        if (snapshot != null && snapshot.exists && mounted) {
          final data = snapshot.data() as Map<String, dynamic>?;
          if (data != null) {
            final langCode = data['preferredLanguage'] ?? 'en';
            debugPrint('Language changed to: $langCode');
            if (_locale.languageCode != langCode) {
              setState(() {
                _locale = Locale(langCode, '');
              });
              // Sync to SharedPreferences for offline/pre-login access
              SharedPreferences.getInstance().then(
                (prefs) => prefs.setString('preferred_language', langCode),
              );
            }
          }
        }
      },
      onError: (error) {
        debugPrint('Error listening to language changes: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: _locale,
          navigatorKey: navigatorKey,
          localeResolutionCallback: (locale, supportedLocales) {
            // Check if the current device locale is supported
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale?.languageCode) {
                return supportedLocale;
              }
            }
            // If not supported, return English as default
            return const Locale('en', '');
          },
          navigatorObservers: [_analyticsService.getAnalyticsObserver()],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: _showSplash
              ? const SplashScreen()
              : StreamBuilder<User?>(
                  stream: _authService.authStateChanges,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasData) {
                      return const BottomNavBarWidget();
                    }
                    return const LogInScreen();
                  },
                ),
        );
      },
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
