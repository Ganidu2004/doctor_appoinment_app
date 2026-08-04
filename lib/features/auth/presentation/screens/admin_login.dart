import 'package:appoinment_app/core/constants.dart';
import 'package:appoinment_app/features/auth/presentation/screens/auth_gate.dart';
import 'package:appoinment_app/features/auth/presentation/widgets/auth_notification_banner.dart';
import 'package:appoinment_app/core/services/notification_services.dart';
import 'package:appoinment_app/shared/widgets/doc_time_logo.dart';
import 'package:appoinment_app/shared/widgets/web_auth_wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordHidden = true;
  String _notificationMessage = '';
  bool _isSuccessNotification = false;

  Future<void> _loginAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _notificationMessage = '';
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ).timeout(const Duration(seconds: 10));

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .get()
          .timeout(const Duration(seconds: 8));
      final userData = userDoc.data();
      final role = (userData?['role'] ?? '').toString().toLowerCase();

      if (role != 'admin') {
        await FirebaseAuth.instance.signOut();
        throw FirebaseAuthException(
          code: 'unauthorized',
          message: 'Access denied. Admin credentials required.',
        );
      }

      if (!mounted) return;
      
      // Call notifications asynchronously to prevent blocking the UI/login flow
      NotificationService().showLoginNotification().catchError((e) {
        debugPrint('Notification error: $e');
      });

      setState(() {
        _notificationMessage = 'Admin login successful. Redirecting...';
        _isSuccessNotification = true;
      });

      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthGate()));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _notificationMessage = e.message ?? 'Admin login failed. Check your credentials.';
        _isSuccessNotification = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notificationMessage = e.toString().contains('TimeoutException')
            ? 'Connection timed out. Please check your internet connection.'
            : 'Unable to authenticate admin account.';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebAuthWrapper(
      heroTagline: "Admin Management Console",
      heroDescription: "Access system administrative settings, manage doctors and hospitals, inspect revenues, and monitor real-time appointments.",
      heroIcon: Icons.admin_panel_settings_rounded,
      featurePoints: const [
        "Doctor & Hospital Approval Desk",
        "Executive Revenue & Month-by-Month Reports",
        "Live Helpdesk Chat Room Support",
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DocTimeLogo(
              variant: DocTimeLogoVariant.vertical,
              iconSize: 56,
              fontSize: 28,
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to your Administrator Account',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: 'Admin Email',
                prefixIcon: const Icon(Icons.admin_panel_settings_outlined, color: primaryColor),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryColor, width: 2)),
              ),
              validator: (val) => val == null || !val.contains('@') ? 'Enter a valid admin email' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _isPasswordHidden,
              style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined, color: primaryColor),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryColor, width: 2)),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: primaryColor.withValues(alpha: 0.7)),
                  onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                ),
              ),
              validator: (val) => val == null || val.isEmpty ? 'Password is required' : null,
            ),
            const SizedBox(height: 16),
            AuthNotificationBanner(
              key: ValueKey(_notificationMessage),
              message: _notificationMessage,
              type: _isSuccessNotification ? NotificationType.success : NotificationType.error,
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _loginAdmin,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Admin Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Normal Sign In', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
