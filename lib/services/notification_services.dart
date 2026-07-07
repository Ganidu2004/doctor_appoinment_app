import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background Message handling: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Session flags to avoid duplicate notifications during one app run
  static bool _loginNotified = false;

  Future<void> initNotifications() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      }

      String? token = await _messaging.getToken().timeout(const Duration(seconds: 4));
      print("FCM Token: $token");

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      _initLocalNotifications();
      
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
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
      print("FCM/Notification Init Error (continuing launch): $e");
    }
  }

  void _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
        
    await _localNotifications.initialize(
      settings: initializationSettings, 
    );
  }


  Future<void> showLoginNotification() async {
    // Avoid spamming the user on rebuilds; show once per app run unless reset
    if (_loginNotified) return;
    _loginNotified = true;

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
      title: 'Welcome DOC TIME App! 👋', 
      body: 'You have successfully logged in.', 
      notificationDetails: notificationDetails, 
    );
  }

  Future<void> showDoctorCreatedNotification() async {
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
      title: 'Doctor Account Created',
      body: 'Your doctor account has been created successfully.',
      notificationDetails: notificationDetails,
    );
  }

  Future<void> showPatientCreatedNotification() async {
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
      title: 'Patient Account Created',
      body: 'Your patient account has been created successfully.',
      notificationDetails: notificationDetails,
    );
  }

  Future<void> showScheduleCreatedNotification() async {
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
      title: 'Doctor Schedule Created',
      body: 'The doctor schedule was created.',
      notificationDetails: notificationDetails,
    );
  }
}