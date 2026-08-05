import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:appoinment_app/core/theme_controller.dart';

class AddAdminUserPage extends StatefulWidget {
  const AddAdminUserPage({super.key});

  @override
  State<AddAdminUserPage> createState() => _AddAdminUserPageState();
}

class _AddAdminUserPageState extends State<AddAdminUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedAdminRole = 'System Administrator';
  bool _isSaving = false;
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  final List<String> _adminRoles = [
    'System Administrator',
    'Super Admin',
    'Operations Admin',
    'Financial Admin',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDeco(String label, IconData icon, bool isDark, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: TextStyle(
        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF4F46E5),
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      prefixIcon: Icon(icon, color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5), size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF4F46E5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Future<void> _createAdminAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    FirebaseApp? tempApp;

    try {
      final appName = 'AdminCreator_${DateTime.now().millisecondsSinceEpoch}';
      tempApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final userCredential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(newUid).set({
        'name': name,
        'email': email,
        'role': 'admin',
        'adminRole': _selectedAdminRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text("Admin account for $name created successfully!")),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Failed to create admin account."),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to create admin: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (tempApp != null) {
        try {
          await tempApp.delete();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Add New Admin User", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF0F172A)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
              color: isDark ? Colors.amber : Colors.indigo,
            ),
            tooltip: "Toggle Dark/Light Mode",
            onPressed: () {
              ThemeController.instance.toggleTheme(!isDark);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 760 : 500),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.withValues(alpha: isDark ? 0.2 : 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF7C3AED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      "ACCESS CONTROL",
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Create Admin Account",
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Grant administrative credentials and portal access.",
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isDesktop) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _nameController,
                                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                        decoration: _fieldDeco("Admin Full Name", Icons.person_outline_rounded, isDark),
                                        validator: (val) => val == null || val.trim().isEmpty ? 'Please enter admin name' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                        decoration: _fieldDeco("Admin Email Address", Icons.email_outlined, isDark),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Please enter email';
                                          if (!val.contains('@')) return 'Enter a valid email address';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _passwordController,
                                        obscureText: _isPasswordHidden,
                                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                        decoration: _fieldDeco(
                                          "Password",
                                          Icons.lock_outline_rounded,
                                          isDark,
                                          suffixIcon: IconButton(
                                            icon: Icon(_isPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: isDark ? const Color(0xFF94A3B8) : Colors.grey),
                                            onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                                          ),
                                        ),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Please enter password';
                                          if (val.trim().length < 6) return 'Password must be at least 6 characters';
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _confirmPasswordController,
                                        obscureText: _isConfirmPasswordHidden,
                                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                        decoration: _fieldDeco(
                                          "Confirm Password",
                                          Icons.lock_outline_rounded,
                                          isDark,
                                          suffixIcon: IconButton(
                                            icon: Icon(_isConfirmPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: isDark ? const Color(0xFF94A3B8) : Colors.grey),
                                            onPressed: () => setState(() => _isConfirmPasswordHidden = !_isConfirmPasswordHidden),
                                          ),
                                        ),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Please confirm password';
                                          if (val.trim() != _passwordController.text.trim()) return 'Passwords do not match';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                TextFormField(
                                  controller: _nameController,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  decoration: _fieldDeco("Admin Full Name", Icons.person_outline_rounded, isDark),
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter admin name' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  decoration: _fieldDeco("Admin Email Address", Icons.email_outlined, isDark),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Please enter email';
                                    if (!val.contains('@')) return 'Enter a valid email address';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _isPasswordHidden,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  decoration: _fieldDeco(
                                    "Password",
                                    Icons.lock_outline_rounded,
                                    isDark,
                                    suffixIcon: IconButton(
                                      icon: Icon(_isPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: isDark ? const Color(0xFF94A3B8) : Colors.grey),
                                      onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Please enter password';
                                    if (val.trim().length < 6) return 'Password must be at least 6 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _isConfirmPasswordHidden,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  decoration: _fieldDeco(
                                    "Confirm Password",
                                    Icons.lock_outline_rounded,
                                    isDark,
                                    suffixIcon: IconButton(
                                      icon: Icon(_isConfirmPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: isDark ? const Color(0xFF94A3B8) : Colors.grey),
                                      onPressed: () => setState(() => _isConfirmPasswordHidden = !_isConfirmPasswordHidden),
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Please confirm password';
                                    if (val.trim() != _passwordController.text.trim()) return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                              ],

                              const SizedBox(height: 18),

                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _selectedAdminRole,
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                decoration: _fieldDeco("Administrative Role Level", Icons.admin_panel_settings_outlined, isDark),
                                items: _adminRoles
                                    .map((r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(r, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedAdminRole = val);
                                },
                              ),

                              const SizedBox(height: 32),

                              Row(
                                children: [
                                  if (isDesktop) ...[
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 50),
                                          foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
                                          side: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  Expanded(
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: _isSaving ? null : _createAdminAccount,
                                        icon: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
                                        label: _isSaving
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                              )
                                            : const Text(
                                                'Create Admin User',
                                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                              ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
