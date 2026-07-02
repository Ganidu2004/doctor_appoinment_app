import 'package:appoinment_app/app_theme.dart';
import 'package:appoinment_app/screens/auth_gate.dart';
import 'package:appoinment_app/services/notification_services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await NotificationService().initNotifications();

  await Supabase.initialize(
    url: 'https://wpzmyoryvvbftrooqobm.supabase.co', 
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInJlZiI6Indwem15b3J5dnZiZnRyb29xb2JtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE4NzM5ODQsImV4cCI6MjA5NzQ0OTk4NH0.fKWmEnVp-5NlbwOk6cf2cxPtJQAj9Enma55eMOhj9fk',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Appointment App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}
