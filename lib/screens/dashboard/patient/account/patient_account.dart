import 'package:appoinment_app/screens/dashboard/patient/account/edite_patient_account.dart';
import 'package:appoinment_app/screens/dashboard/patient/appointments/patient_appointments_page.dart';
import 'package:appoinment_app/screens/dashboard/patient/payments/patient_payment_history_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appoinment_app/screens/login.dart';

void main() {
  runApp(const PatientAccount());
}

class PatientAccount extends StatelessWidget {
  final bool showAppBar;
  const PatientAccount({super.key, this.showAppBar = false});

  @override
  Widget build(BuildContext context) {
    return PatientSettingsProfilePage(showAppBar: showAppBar);
  }
}

class PatientSettingsProfilePage extends StatefulWidget {
  final bool showAppBar;
  const PatientSettingsProfilePage({super.key, this.showAppBar = false});

  @override
  State<PatientSettingsProfilePage> createState() => _PatientSettingsProfilePageState();
}

class _PatientSettingsProfilePageState extends State<PatientSettingsProfilePage> {
  bool _pushNotifications = false;
  String _patientName = 'Loading...';
  String _patientSubtitle = 'Please wait...';
  String _profileImageUrl = ''; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatientData(); 
  }

  Future<void> _fetchPatientData() async {
    setState(() {
      _isLoading = true; 
    });
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        debugPrint("DocConnect UID: ${currentUser.uid}");

        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(currentUser.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          debugPrint("DocConnect Data: $data");

          String name = data['name'] ?? 'No Name Provided';
          String age = data['age']?.toString() ?? ''; 
          String city = data['city'] ?? '';
          String imageUrl = data['profileImageUrl'] ?? '';

          setState(() {
            _patientName = name;
            _patientSubtitle = (age.isNotEmpty && city.isNotEmpty)
                ? 'Age: $age • $city'
                : (city.isNotEmpty ? city : 'Patient Account');
            _profileImageUrl = imageUrl;
            _isLoading = false;
          });
        } else {
          setState(() {
            _patientName = 'New Patient';
            _patientSubtitle = 'Profile not set up yet';
            _profileImageUrl = '';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _patientName = 'Not Logged In';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("DocConnect Error: $e");
      setState(() {
        _patientName = 'Error Loading Data';
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out from DocConnect?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              },
              child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              title: const Text('Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              centerTitle: true,
            )
          : null,      body: RefreshIndicator(
        onRefresh: _fetchPatientData,
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profile Section (Redesigned with Premium Gradient & Card)
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative Mesh
                      Positioned(
                        right: -40,
                        top: -40,
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      Positioned(
                        left: -20,
                        bottom: -40,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white.withValues(alpha: 0.03),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                        child: Column(
                          children: [
                            Center(
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 48,
                                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                                      backgroundImage: _profileImageUrl.isNotEmpty
                                          ? NetworkImage(_profileImageUrl)
                                          : null,
                                      child: _profileImageUrl.isEmpty
                                          ? const Icon(Icons.person_outline, size: 40, color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.verified_rounded,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _patientName,
                              style: const TextStyle(
                                fontSize: 22, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _patientSubtitle,
                              style: TextStyle(
                                fontSize: 13, 
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Patient Member',
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Account Management Section
                _buildSectionHeader('Account Management'),
                
                _buildListTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Personal Information',
                  subtitle: 'Manage your name, age, city and contact details',
                  onTap: () async {
                    User? currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser != null) {
                      final isUpdated = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PatientProfileEditPage(
                            userId: currentUser.uid,
                          ),
                        ),
                      );
                      if (isUpdated == true) {
                        _fetchPatientData();
                      }
                    }
                  },
                ),
                
                _buildListTile(
                  icon: Icons.assignment_outlined,
                  title: 'Medical Records',
                  subtitle: 'View your prescriptions and test reports',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Medical records are coming soon.')),
                    );
                  },
                ),
                _buildListTile(
                  icon: Icons.calendar_month_outlined,
                  title: 'Appointments History',
                  subtitle: 'Check your past and upcoming channelings',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PatientAppointmentsPage(showAppBar: true),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  icon: Icons.payment_outlined,
                  title: 'Payment History',
                  subtitle: 'Review your past payments and charges',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PatientPaymentHistoryPage(),
                      ),
                    );
                  },
                ),

                // Preferences Section
                _buildSectionHeader('Preferences'),
                _buildSwitchTile(
                  icon: Icons.notifications_none_outlined,
                  title: 'Push Notifications',
                  subtitle: 'Customize alerts and reminders',
                  value: _pushNotifications,
                  onChanged: (val) => setState(() => _pushNotifications = val),
                ),

                // Support & Legal Section
                _buildSectionHeader('Support & Legal'),
                _buildListTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help Center',
                  subtitle: 'FAQs and live support',
                  onTap: () {},
                ),
                _buildListTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
                _buildListTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () {},
                ),

                const SizedBox(height: 32),
                
                // Sign Out Button (Styled to fit premium aesthetics)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _showSignOutDialog, 
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade100, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Colors.red.shade50.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Version Info Footer
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Version 2.4.1 (Build 890)',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'DOCCONNECT INC. © 2024',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon, 
    required String title, 
    String? subtitle, 
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFE3EDFF), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: const Color(0xFF1E88E5), size: 22),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)) : null,
          trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
          onTap: onTap, 
        ),
        Padding(
          padding: const EdgeInsets.only(left: 70.0, right: 16.0),
          child: Divider(color: Colors.grey.shade100, height: 1),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required bool value, 
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFE3EDFF), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: const Color(0xFF1E88E5), size: 22),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          trailing: Switch.adaptive(
            value: value,
            activeTrackColor: const Color(0xFF1E88E5),
            activeThumbColor: const Color(0xFF1E88E5),
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 70.0, right: 16.0),
          child: Divider(color: Colors.grey.shade100, height: 1),
        ),
      ],
    );
  }
}