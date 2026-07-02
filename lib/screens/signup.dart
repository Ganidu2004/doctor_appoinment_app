import 'package:appoinment_app/const.dart';
import 'package:appoinment_app/screens/auth_gate.dart';
import 'package:appoinment_app/screens/auth_notification_banner.dart';
import 'package:appoinment_app/services/notification_services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); 
  
  String _selectedRole = 'Patient'; 
  final List<String> _roles = ['Patient', 'Doctor'];
  bool _isLoading = false;
  
  bool _isPasswordHidden = true; 
  bool _isConfirmPasswordHidden = true; 

  // Notification Banner Tracking States
  String _notificationMessage = '';
  bool _isSuccessNotification = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _notificationMessage = ''; 
    });

    try {
      // 1. Create user in Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return; 

      // 2. Save supplementary details to Cloud Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': _emailController.text.trim(),
        'role': _selectedRole.toString().toLowerCase(),
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return; 
      
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      // Show a local notification for account creation based on selected role
      try {
        if (_selectedRole == 'Doctor') {
          await NotificationService().showDoctorCreatedNotification();
        } else {
          await NotificationService().showPatientCreatedNotification();
        }
      } catch (e) {
        // ignore notification errors to not block navigation
        print('Notification error: $e');
      }
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );

      setState(() {
        _notificationMessage = 'Account registered successfully!';
        _isSuccessNotification = true;
      });

      // Brief delay so the user can actually see the success message component
      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) Navigator.pop(context); 
    } on FirebaseAuthException catch (e) {
      if (!mounted) return; // 👈 Guard check
      setState(() {
        _notificationMessage = e.message ?? 'Registration failed';
        _isSuccessNotification = false;
      });
    } catch (e) {
      if (!mounted) return; // 👈 Guard check
      setState(() {
        _notificationMessage = 'An unexpected error occurred.';
        _isSuccessNotification = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBgColor,
      appBar: AppBar(
        backgroundColor: lightBgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                  // --- Brand Header Logo & Text ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded, 
                      size: 64, 
                      color: primaryColor
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Create Account', 
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
                    'Join DOC TIME to book and manage appointments.', 
                    textAlign: TextAlign.center, 
                    style: TextStyle(
                      fontSize: 15, 
                      color: darkTextColor.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // --- Email Address Field ---
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
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Email is required';
                      if (!val.contains('@') || !val.contains('.')) return 'Invalid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
          
                  // --- Role Dropdown Field ---
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.w500, fontSize: 16),
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Select Profile Type', 
                      labelStyle: TextStyle(color: darkTextColor.withValues(alpha: 0.5)),
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: primaryColor),
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
                    items: _roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                    onChanged: (value) => setState(() => _selectedRole = value!),
                  ),
                  const SizedBox(height: 20),
          
                  // --- Password Field ---
                  TextFormField(
                    controller: _passwordController, 
                    obscureText: _isPasswordHidden,
                    style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'Password', 
                      labelStyle: TextStyle(color: darkTextColor.withValues(alpha: 0.5)),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: primaryColor),
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
                        onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                      ),
                    ), 
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Password is required';
                      if (val.length < 8) return 'Password must be at least 8 characters long';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
          
                  // --- Confirm Password Field ---
                  TextFormField(
                    controller: _confirmPasswordController, 
                    obscureText: _isConfirmPasswordHidden,
                    style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password', 
                      labelStyle: TextStyle(color: darkTextColor.withValues(alpha: 0.5)),
                      prefixIcon: const Icon(Icons.lock_clock_outlined, color: primaryColor),
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
                          _isConfirmPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: primaryColor.withValues(alpha: 0.7),
                        ),
                        onPressed: () => setState(() => _isConfirmPasswordHidden = !_isConfirmPasswordHidden),
                      ),
                    ), 
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Please confirm your password';
                      if (val != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // --- Integrated Custom Component ---
                  AuthNotificationBanner(
                    key: ValueKey(_notificationMessage),
                    message: _notificationMessage,
                    type: _isSuccessNotification ? NotificationType.success : NotificationType.error,
                  ),
          
                  // --- Premium Submit Button ---
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
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
                            'Register Account', 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // --- Footer Back to Login Screen Link ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(color: darkTextColor.withValues(alpha: 0.6), fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            color: primaryColor, 
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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