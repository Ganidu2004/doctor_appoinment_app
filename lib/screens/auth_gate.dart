import 'package:appoinment_app/screens/dashboard/doctor/navigator/navigator.dart';
import 'package:appoinment_app/screens/dashboard/patient/navigator/navigator.dart';
import 'package:appoinment_app/services/notification_services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'dashboard/admin_dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData) {
          // Post-frame callback to avoid calling during build; NotificationService guards duplicates
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              NotificationService().showLoginNotification();
            } catch (e) {
              print('Login notification error: $e');
            }
          });

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                String role = (userData['role'] ?? 'patient').toString().toLowerCase();

                if (role == 'doctor') return const MainLayout();
                if (role == 'admin') return const AdminDashboard();
                if (role == 'patient') return const PatientMainLayout();

                // Unknown or invalid role: sign out and force login again.
                FirebaseAuth.instance.signOut();
                return const LoginScreen();
              }

              return const LoginScreen();
            },
          );
        }
        
        return const LoginScreen();
      },
    );
  }
}