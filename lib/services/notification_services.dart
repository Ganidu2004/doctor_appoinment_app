import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Background Message handling: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Session flags to avoid duplicate notifications during one app run
  static bool _loginNotified = false;

  Future<void> initNotifications() async {
    // Firebase Messaging is not supported on Windows/macOS/Linux
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || 
                    defaultTargetPlatform == TargetPlatform.linux || 
                    defaultTargetPlatform == TargetPlatform.macOS)) {
      debugPrint("FCM is not supported on desktop platforms. Skipping FCM initialization.");
      return;
    }

    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      }

      String? token = await _messaging.getToken().timeout(const Duration(seconds: 4));
      debugPrint("FCM Token: $token");

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      _initLocalNotifications();
      
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          _saveNotificationToFirestore(notification.title ?? '', notification.body ?? '');

          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel', 
                'High Importance Notifications', 
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher', 
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint("FCM/Notification Init Error (continuing launch): $e");
    }
  }

  void _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
        
    await _localNotifications.initialize(
      settings: initializationSettings, 
    );
  }


  Future<void> _saveNotificationToFirestore(String title, String body) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': user.uid,
          'title': title,
          'body': body,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    } catch (e) {
      debugPrint("Error saving notification to Firestore: $e");
    }
  }

  Future<void> showLoginNotification() async {
    // Avoid spamming the user on rebuilds; show once per app run unless reset
    if (_loginNotified) return;
    _loginNotified = true;

    const title = 'Welcome DOC TIME App! 👋';
    const body = 'You have successfully logged in.';
    await _saveNotificationToFirestore(title, body);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'auth_channel',
      'Authentication Alert',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  Future<void> showDoctorCreatedNotification() async {
    const title = 'Doctor Account Created';
    const body = 'Your doctor account has been created successfully.';
    await _saveNotificationToFirestore(title, body);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'doctor_channel',
      'Doctor Account',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: 10,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  Future<void> showPatientCreatedNotification() async {
    const title = 'Patient Account Created';
    const body = 'Your patient account has been created successfully.';
    await _saveNotificationToFirestore(title, body);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'patient_channel',
      'Patient Account',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: 11,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  Future<void> showScheduleCreatedNotification() async {
    const title = 'Doctor Schedule Created';
    const body = 'The doctor schedule was created.';
    await _saveNotificationToFirestore(title, body);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'schedule_channel',
      'Schedule Created',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: 20,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _saveNotificationToFirestore(title, body);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'general_success_channel',
      'Success Notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}