import 'package:appoinment_app/const.dart';
import 'package:appoinment_app/screens/admin_login.dart';
import 'package:appoinment_app/screens/auth_gate.dart';
import 'package:appoinment_app/screens/auth_notification_banner.dart';
import 'package:appoinment_app/screens/forgot_pass.dart';
import 'package:appoinment_app/services/notification_services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordHidden = true; 

  // Notification Banner Tracking States
  String _notificationMessage = '';
  bool _isSuccessNotification = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _notificationMessage = ''; 
    });

    try {
      // 1. Wait for Firebase response
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ).timeout(const Duration(seconds: 10));

      // 2. CHECK MOUNTED IMMEDIATELY AFTER THE AWAIT
      if (!mounted) return;

      // Call notifications asynchronously to prevent blocking the UI/login flow
      NotificationService().showLoginNotification().catchError((e) {
        debugPrint('Notification error: $e');
      }); 

      setState(() {
        _notificationMessage = 'Login successful! Redirecting...';
        _isSuccessNotification = true;
      });

      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const AuthGate(), 
        ),
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return; // 👈 Safety return check
      setState(() {
        _notificationMessage = e.message ?? 'Login failed. Please check credentials.';
        _isSuccessNotification = false;
      });
    } catch (e) {
      if (!mounted) return; // 👈 Safety return check
      setState(() {
        _notificationMessage = e.toString().contains('TimeoutException')
            ? 'Connection timed out. Please check your internet connection.'
            : 'An unexpected error occurred.';
        _isSuccessNotification = false;
      });
    } finally {
      // 3. Final safety lock
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Brand Identity & Welcome Header ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded, 
                      size: 72, 
                      color: primaryColor
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'DOC TIME', 
                    textAlign: TextAlign.center, 
                    style: TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.w900, 
                      color: darkTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Book appointments with your favorite doctors seamlessly.', 
                    textAlign: TextAlign.center, 
                    style: TextStyle(
                      fontSize: 15, 
                      color: darkTextColor.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // --- Email Input Field ---
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'Email Address', 
                      labelStyle: TextStyle(color: darkTextColor.withValues(alpha: 0.5)),
                      prefixIcon: const Icon(Icons.email_outlined, color: primaryColor), 
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                    validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email address' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  // --- Password Input Field ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isPasswordHidden,
                    style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'Password', 
                      labelStyle: TextStyle(color: darkTextColor.withValues(alpha: 0.5)),
                      prefixIcon: const Icon(Icons.lock_outlined, color: primaryColor), 
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: primaryColor, width: 2),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: primaryColor.withValues(alpha: 0.7),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordHidden = !_isPasswordHidden;
                          });
                        },
                      ),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Password is required' : null,
                  ),
                  
                  // --- Forgot Password Button ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: primaryColor.withValues(alpha: 0.9), 
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // --- Integrated Custom Component ---
                  AuthNotificationBanner(
                    key: ValueKey(_notificationMessage),
                    message: _notificationMessage,
                    type: _isSuccessNotification ? NotificationType.success : NotificationType.error,
                  ),
                  
                  // --- Premium Animated Submit Button ---
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, 
                      foregroundColor: Colors.white, 
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading 
                        ? const SizedBox(
                            height: 24, 
                            width: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          ) 
                        : const Text(
                            'Sign In', 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                  ),
                  const SizedBox(height: 24),
                  
                  // --- Footer Link to Sign Up Screen ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: darkTextColor.withValues(alpha: 0.6), fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignUpScreen()),
                        ),
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            color: primaryColor, 
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                      );
                    },
                    child: const Text(
                      'Admin Login',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}