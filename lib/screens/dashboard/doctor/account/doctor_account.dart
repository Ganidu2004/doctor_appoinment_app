import 'package:appoinment_app/screens/dashboard/doctor/account/edite_doctor_account.dart';
import 'package:appoinment_app/screens/dashboard/doctor/modles/user_profile.dart';
import 'package:appoinment_app/screens/dashboard/doctor/payments/doctor_billing_page.dart';
import 'package:appoinment_app/screens/login.dart'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

class DoctorAccount extends StatelessWidget {
  const DoctorAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsProfilePage();
  }
}

class SettingsProfilePage extends StatefulWidget {
  const SettingsProfilePage({super.key});

  @override
  State<SettingsProfilePage> createState() => _SettingsProfilePageState();
}

class _SettingsProfilePageState extends State<SettingsProfilePage> {
  bool _pushNotifications = false;
  String _doctorName = 'Loading...';
  String _doctorTitle = 'Please wait...';
  String _hospital = '';
  String _profileImageUrl = '';
  bool _isLoading = true;
  Map<String, dynamic> _allDoctorData = {};

  @override
  void initState() {
    super.initState();
    _fetchDoctorData(); 
  }

  Future<void> _fetchDoctorData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(currentUser.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          DoctorModel doctor = DoctorModel.fromMap(data);

          String hospitalName = '';
          if (doctor.hospitalsList.isNotEmpty) {
            hospitalName = doctor.hospitalsList[0]['hospitalName'] ?? '';
          }

          setState(() {
            _allDoctorData = data; 
            _doctorName = doctor.name.isNotEmpty ? doctor.name : 'No Name Provided';
            _doctorTitle = doctor.specialization.isNotEmpty ? doctor.specialization : 'Medical Professional';
            _hospital = hospitalName; 
            _profileImageUrl = doctor.profileImageUrl;
            _isLoading = false;
          });
        } else {
          setState(() {
            _doctorName = 'New Doctor';
            _doctorTitle = 'Profile not set up yet';
            _hospital = '';
            _profileImageUrl = '';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _doctorName = 'Not Logged In';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _doctorName = 'Error Loading Data';
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
              onPressed: () {
                Navigator.of(context).pop(); 
              },
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchDoctorData,
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium Creative Header Curve
                Stack(
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 240),
                      painter: HeaderCurvePainter(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
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
                                    radius: 44,
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
                                      color: Color(0xFF0EA5E9),
                                      size: 18,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _doctorName,
                            style: const TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hospital.isNotEmpty ? '$_doctorTitle • $_hospital' : _doctorTitle,
                            style: TextStyle(
                              fontSize: 12, 
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Account Management Section
                _buildSectionHeader('Account Management'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildListTile(
                            icon: Icons.person_outline,
                            title: 'Personal Information',
                            subtitle: 'Manage your name, email and phone',
                            isFirst: true,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => DoctorProfileEditPage(
                                    doctorData: _allDoctorData,
                                  ),
                                ),
                              );
                              _fetchDoctorData();
                            },
                          ),
                          _buildListTile(
                            icon: Icons.shield_outlined,
                            title: 'Medical Credentials',
                            subtitle: 'Verification status and certifications',
                            onTap: () {},
                          ),
                          _buildListTile(
                            icon: Icons.credit_card_outlined,
                            title: 'Payment & Billing',
                            subtitle: 'Bank accounts and transaction history',
                            isLast: true,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const DoctorBillingPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Preferences Section
                _buildSectionHeader('Preferences'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            icon: Icons.notifications_none_outlined,
                            title: 'Push Notifications',
                            subtitle: 'Customize alerts and reminders',
                            value: _pushNotifications,
                            onChanged: (val) => setState(() => _pushNotifications = val),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 56.0, right: 16.0),
                            child: Divider(color: Colors.grey.shade100, height: 1),
                          ),
                          _buildListTile(
                            icon: Icons.language_outlined,
                            title: 'Language',
                            subtitle: 'English (United States)',
                            isLast: true,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Support & Legal Section
                _buildSectionHeader('Support & Legal'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildListTile(
                            icon: Icons.help_outline_rounded,
                            title: 'Help Center',
                            subtitle: 'FAQs and live support',
                            isFirst: true,
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
                            isLast: true,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                
                // Sign Out Button
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
      padding: const EdgeInsets.only(left: 20.0, top: 20.0, bottom: 10.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon, 
    required String title, 
    String? subtitle, 
    bool isFirst = false,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: isFirst ? const Radius.circular(20) : Radius.zero,
              bottom: isLast ? const Radius.circular(20) : Radius.zero,
            ),
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
          subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)) : null,
          trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 14),
          onTap: onTap, 
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 56.0, right: 16.0),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: Switch.adaptive(
        value: value,
        activeTrackColor: const Color(0xFF2563EB),
        activeThumbColor: Colors.white,
        onChanged: onChanged,
      ),
    );
  }
}

class HeaderCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.lineTo(0, size.height * 0.75);
    
    var firstControlPoint = Offset(size.width * 0.25, size.height);
    var firstEndPoint = Offset(size.width * 0.5, size.height * 0.85);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    
    var secondControlPoint = Offset(size.width * 0.75, size.height * 0.7);
    var secondEndPoint = Offset(size.width, size.height * 0.85);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);
    
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}