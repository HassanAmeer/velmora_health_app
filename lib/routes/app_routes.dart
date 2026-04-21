import 'package:velmora/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const premiumView = '/premiumView';
  static const home = '/home';
  static const paywallScreen = '/paywallScreen';
  static const dashboard = '/dashboard';
  static const analyzingScreen = '/analyzingScreen';
  static const searchmusicscreen = '/searchmusicscreen';
  static const turnbtscreen = '/turnbtscreen';
  static const btscreen = '/btscreen';
  static const backwardScreen = '/backwardScreen';
  static const likedsongs = '/likedsongs';
  static const savedsongs = '/savedsongs';
  static const recentlyplayedsongs = '/recentlyplayedsongs';
  static const importedsongs = '/importedsongs';
  static const languagescreen = '/languagescreen';
  static const proscreen = '/proscreen';
  static const equalizerscreen = '/equalizerscreen';
  static const btflowpage = '/btflowpage';
  static const nowplayingsc = '/nowplayingscreen';
  static const playlist = '/playlist';
  static const languagefirst = '/languagefirst';

  static const downloadScreen = '/downloadScreen';
  static const removeScreen = '/removeScreen';
  static const slowScreen = '/slowScreen';
  static const historyScreen = '/historyScreen';
  static const videoPreviewScreen = '/videoPreviewScreen';
  static const congrats = '/congrats';
  static const compress_preview = '/compress_preview';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    // onboarding: (context) => const OnboardingScreen(),
    // home: (context) => const HomeScreen(),

    // dashboard: (context) => DashboardScreen(),

    // turnbtscreen: (context) => const TurnBtScreen(),
    // // btscreen: (context) => BluetoothMainScreen(),
    // proscreen: (context) => PremiumScreen(),
    // playlist: (context) => PlaylistDetailScreen(),

    // searchmusicscreen: (context) => SearchMusicScreen(),
    // likedsongs: (context) => LikedSongsScreen(),
    // savedsongs: (context) => SavedSongsScreen(),
    // recentlyplayedsongs: (context) => RecentlyPlayedSongsScreen(),
    // importedsongs: (context) => ImportedSongsScreen(),
    // languagescreen: (context) => LocalizationScreen(),
    // equalizerscreen: (context) => SoundEqualizerScreen(),
    // btflowpage: (context) => BluetoothFlowPage(),
    // nowplayingsc: (context) => NowPlayingScreen(),
    // languagefirst: (context) => LanguageFirstScreen(),
    // signup: (context) => SignupScreen(),
    // bottomBar: (context) => BottombarMain(),
    // // home: (context) => PhoneStorageScreen(),
    // imagesScreen: (context) => ImagesScreen(),
    // docScreen: (context) => DocumentsScreen(),
    // audioScreen: (context) => AudioScreen(),
    // videoScreen: (context) => VideosScreen(),
    // contactScreen: (context) => ContactScreen(),
    // // phonestorageView: (context) => StorageView(),
    // forgetScreen: (context) => ForgetScreen(),
    // otpScreen: (context) => OtpScreen(),
    // resetPassScreen: (context) => ResetPasswordScreen(),
    // paywallScreen: (context) => PaywallScreen(),
    // editScreen: (context) => EditScreen(),
    // imagePreview: (context) => ImagesPreviewScreen(),
    // videoPreview: (context) => VideosPreviewScreen(),
    // documentPreview: (context) => DocumentsPreviewScreen(),
    // audioPreview: (context) => AudioPreviewScreen(),
    // contactPreview: (context) => ContactPreviewScreen(),
    // contactSelection: (context) => ContactsSelection(),
  };
}

// route generator

// class AppRouteGenerator {
//   static Route<dynamic>? generateRoute(RouteSettings settings) {
//     if (settings.name == AppRoutes.drawerScreen) {
//       return PageRouteBuilder(
//         pageBuilder: (_, __, ___) => DrawerScreen(),
//         transitionsBuilder: (_, animation, __, child) {
//           const begin = Offset(-1.0, 0.0); // slide from left
//           const end = Offset.zero;
//           const curve = Curves.easeInOut;

//           var tween = Tween(
//             begin: begin,
//             end: end,
//           ).chain(CurveTween(curve: curve));
//           return SlideTransition(
//             position: animation.drive(tween),
//             child: child,
//           );
//         },
//       );
//     }
//     return null; // fallback → MaterialApp uses `routes:` normally
//   }
// }
