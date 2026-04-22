import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter/material.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:velmora/main.dart";
import "package:velmora/screens/settings/notifications_screen.dart";

// for background message listen
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("👉 BG Notify: ${message.notification?.title} ");
}

class Notify {
  FirebaseMessaging msg = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('ic_notification');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidInitializationSettings,
          iOS: iosInitializationSettings,
        );

    // Create the channel for Android
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'high_importance_channel',
            'High Importance Notifications',
            description: 'This channel is used for important notifications.',
            importance: Importance.max,
          ),
        );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("👉 Local Notification Clicked: ${details.payload}");
        _navigateToNotifications();
      },
    );
  }

  static void _navigateToNotifications() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  void requestNotifyPermissionF() async {
    NotificationSettings stngs = await msg.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );
    if (stngs.authorizationStatus == AuthorizationStatus.authorized) {
      // have permission
    } else if (stngs.authorizationStatus == AuthorizationStatus.provisional) {
      // request permission => provisional means provide
    } else {
      // have no notify permission
    }

    // Initialize local notifications as well
    await initializeLocalNotifications();
  }

  // get token for use to send notification
  Future getTokenF() async {
    String? token = await msg.getToken();
    debugPrint("👉 token: $token");

    // Save token to Firestore
    try {
      final prefs = await SharedPreferences.getInstance();
      String? uid = prefs.getString('uid'); // Use UID from local storage

      // Fallback to FirebaseAuth if local storage UID is missing
      if (uid == null) {
        final user = FirebaseAuth.instance.currentUser;
        uid = user?.uid;
      }

      if (uid != null && token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': token,
        });

        // Subscribe to a topic for "All Users" notifications
        await msg.subscribeToTopic('all');

        debugPrint(
          "👉 FCM token saved and subscribed to 'all' topic for user: $uid",
        );
      }
    } catch (e) {
      debugPrint("Error saving FCM token or subscribing: $e");
    }
    return token;
  }

  // for refresh the token
  void isTokenRefreshF() {
    msg.onTokenRefresh.listen((event) {
      event.toString();
    });
  }

  // for background notification message
  listenBackgroundNotification() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /////////////////////////
  listenNotificationOnOpendApp() {
    FirebaseMessaging.onMessage.listen((event) {
      debugPrint("👉 IN APP Notify: $event ");
      String title = event.notification?.title ?? "";
      String body = event.notification?.body ?? "";

      // Show local notification when app is in foreground
      showNotification(title: title, body: body);
    });
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_notification', // Using the custom bell icon
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _localNotificationsPlugin.show(0, title, body, notificationDetails);
  }

  // Handle FCM click when app is in background or closed
  onClickFcmNotifi() async {
    // 1. Handle message when app is in background but NOT closed
    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      debugPrint("👉 On Click Notification: $event ");
      _navigateToNotifications();
    });

    // 2. Handle message when app is terminated and opened via notification
    RemoteMessage? initialMessage = await msg.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("👉 App opened from terminated state via notification");
      _navigateToNotifications();
    }
  }
}
