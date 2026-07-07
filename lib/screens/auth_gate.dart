import 'package:appoinment_app/screens/dashboard/admin/admin_dashboard.dart';
import 'package:appoinment_app/screens/dashboard/doctor/navigator/navigator.dart';
import 'package:appoinment_app/screens/dashboard/patient/navigator/navigator.dart';
import 'package:appoinment_app/services/notification_services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';


class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Stream<User?> _authStateStream;
  Future<DocumentSnapshot>? _userDocFuture;
  String? _lastUid;

  @override
  void initState() {
    super.initState();
    _authStateStream = FirebaseAuth.instance.authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData) {
          final uid = snapshot.data!.uid;
          if (_userDocFuture == null || _lastUid != uid) {
            _lastUid = uid;
            _userDocFuture = FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .get()
                .timeout(const Duration(seconds: 8));
          }

          // Post-frame callback to avoid calling during build; NotificationService guards duplicates
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              NotificationService().showLoginNotification();
            } catch (e) {
              print('Login notification error: $e');
            }
          });

          return FutureBuilder<DocumentSnapshot>(
            future: _userDocFuture,
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (userSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off_rounded, color: Colors.red, size: 54),
                          const SizedBox(height: 16),
                          const Text(
                            "Connection Timeout",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userSnapshot.error.toString().contains("TimeoutException")
                                ? "Authentication query timed out. Please check your internet connection and try again."
                                : "Failed to load user profile: ${userSnapshot.error}",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0EA5E9),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              // Reset future cache on logout/retry
                              setState(() {
                                _userDocFuture = null;
                                _lastUid = null;
                              });
                              FirebaseAuth.instance.signOut();
                            },
                            child: const Text("Return to Login"),
                          )
                        ],
                      ),
                    ),
                  ),
                );
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
        
        // Reset future cache on signout
        _userDocFuture = null;
        _lastUid = null;
        return const LoginScreen();
      },
    );
  }
}