import 'package:appoinment_app/screens/dashboard/patient/account/edite_patient_account.dart';
import 'package:appoinment_app/screens/dashboard/patient/appointments/patient_appointments_page.dart';
import 'package:appoinment_app/screens/dashboard/patient/payments/patient_payment_history_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appoinment_app/screens/login.dart';

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
  String _gender = 'Not Set';
  String _bloodGroup = 'O+';
  String _weight = '70 kg';
  int _activeAppointmentsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatientData(); 
  }

  Future<void> _fetchPatientData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true; 
    });
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(currentUser.uid)
            .get();

        final appointmentsSnapshot = await FirebaseFirestore.instance
            .collection('appointments')
            .where('patientUid', isEqualTo: currentUser.uid)
            .get();

        int activeAppts = appointmentsSnapshot.docs.where((doc) {
          final status = (doc.data())['status']?.toString().toLowerCase() ?? '';
          return status != 'cancelled' && status != 'completed';
        }).length;

        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          String name = data['name'] ?? 'No Name Provided';
          String age = data['age']?.toString() ?? ''; 
          String city = data['city'] ?? '';
          String imageUrl = data['profileImageUrl'] ?? '';
          String gender = data['gender'] ?? 'Not Set';
          String blood = data['bloodGroup'] ?? 'O+';
          String weight = data['weight'] ?? '70 kg';

          setState(() {
            _patientName = name;
            _patientSubtitle = (age.isNotEmpty && city.isNotEmpty)
                ? 'Age: $age • $city'
                : (city.isNotEmpty ? city : 'Patient Account');
            _profileImageUrl = imageUrl;
            _gender = gender;
            _bloodGroup = blood;
            _weight = weight;
            _activeAppointmentsCount = activeAppts;
            _isLoading = false;
          });
        } else {
          setState(() {
            _patientName = 'New Patient';
            _patientSubtitle = 'Profile not set up yet';
            _profileImageUrl = '';
            _activeAppointmentsCount = activeAppts;
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              iconTheme: const IconThemeData(color: Colors.black),
              title: const Text('Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              centerTitle: true,
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _fetchPatientData,
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
                            _patientName,
                            style: const TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _patientSubtitle,
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

                // Wavy Metrics Dashboard
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(child: _buildMetricCard("Blood Group", _bloodGroup, Icons.bloodtype, Colors.red.shade400)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildMetricCard("Weight", _weight, Icons.scale_outlined, Colors.orange.shade400)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildMetricCard("Gender", _gender, Icons.wc_rounded, Colors.green.shade400)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Health Insights / Active Channels Status Widget
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Active Channels",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _activeAppointmentsCount > 0
                                    ? "You have $_activeAppointmentsCount upcoming medical visits."
                                    : "No active channeling appointments.",
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (_activeAppointmentsCount > 0)
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const PatientAppointmentsPage(showAppBar: true),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "View",
                                style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Settings Cards Grouped nicely
                _buildSectionHeader('Account settings'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Personal Information',
                          subtitle: 'Manage your name, age, city and contact details',
                          isFirst: true,
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
                          isLast: true,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PatientPaymentHistoryPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                _buildSectionHeader('Preferences'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: _buildSwitchTile(
                      icon: Icons.notifications_none_outlined,
                      title: 'Push Notifications',
                      subtitle: 'Customize alerts and reminders',
                      value: _pushNotifications,
                      onChanged: (val) => setState(() => _pushNotifications = val),
                    ),
                  ),
                ),

                _buildSectionHeader('Support & Legal'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
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

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
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