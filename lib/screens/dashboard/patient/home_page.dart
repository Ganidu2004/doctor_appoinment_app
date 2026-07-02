import 'package:appoinment_app/screens/dashboard/doctor/account/doctor_profile.dart';
import 'package:appoinment_app/screens/dashboard/patient/account/patient_account.dart';
import 'package:appoinment_app/screens/dashboard/patient/appointments/patient_appointments_page.dart';
import 'package:appoinment_app/screens/dashboard/patient/doctor_find_page/find_doctor.dart';
import 'package:appoinment_app/screens/dashboard/patient/support/patient_support_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appoinment_app/screens/dashboard/patient/navigator/header.dart';
import 'package:appoinment_app/screens/dashboard/patient/doctor_find_page/recommond_doctor.dart';
import 'package:intl/intl.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  String _patientName = "Patient";
  String _profileImageUrl = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(currentUser.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            _patientName = data['name'] ?? "Patient";
            _profileImageUrl = data['profileImageUrl'] ?? "";
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchUserData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PatientGreetingHeader(name: _patientName, profileImageUrl: _profileImageUrl),
                      const SizedBox(height: 20),
                      const _UpcomingVisitCard(),
                      const SizedBox(height: 24),
                      const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),
                      const _QuickActionsGrid(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recommended Doctors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecommendedDoctorsPage())),
                            child: const Text('See All', style: TextStyle(color: Colors.blue)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          final doctors = snapshot.data!.docs;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 10, mainAxisSpacing: 10),
                            itemCount: doctors.length >= 2 ? 2 : doctors.length,
                            itemBuilder: (context, index) {
                              final data = doctors[index].data() as Map<String, dynamic>;
                              final String? imageUrl = data['profileImageUrl'];
                              return InkWell(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorDetailPage(doctorId: doctors[index].id))),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          image: imageUrl != null && imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                                        ),
                                        child: imageUrl == null || imageUrl.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.blue) : null,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Dr. ${data['name'] ?? 'Doctor'}', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(data['specialization'] ?? 'General', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ]),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),
                      const _RecentActivityList(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _UpcomingVisitCard extends StatelessWidget {
  const _UpcomingVisitCard();
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('appointments').where('patientUid', isEqualTo: user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
        final now = DateTime.now();
        var docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          try { return DateFormat("MMMM d, yyyy").parse(data['date']).isAfter(now.subtract(const Duration(days: 1))); } catch (e) { return false; }
        }).toList();
        if (docs.isEmpty) return const SizedBox();
        final data = docs.first.data() as Map<String, dynamic>;
        final String? doctorImageUrl = data['doctorImageUrl'];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF3F8FF), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Row(children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                backgroundImage: (doctorImageUrl != null && doctorImageUrl.isNotEmpty) ? NetworkImage(doctorImageUrl) : null,
                child: (doctorImageUrl == null || doctorImageUrl.isEmpty) ? const Icon(Icons.person, size: 30) : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(data['doctorName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(data['specialization'] ?? 'Doctor', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ]),
              ),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(10)),
                child: Text(data['status'], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12))),
            ]),
            const SizedBox(height: 15),
            Row(children: [const Icon(Icons.access_time, size: 16, color: Colors.grey), const SizedBox(width: 5), Text("${data['date']} | ${data['time']}", style: const TextStyle(color: Colors.grey))]),
          ]),
        );
      },
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();
  @override
  Widget build(BuildContext context) {
    final actions = [
      {'icon': Icons.medical_services, 'label': 'Search', 'page': const FindDoctorScreen()},
      {'icon': Icons.calendar_today_outlined, 'label': 'Appointments', 'page': const PatientAppointmentsPage(showAppBar: true)},
      {'icon': Icons.assignment, 'label': 'Profile', 'page': const PatientAccount(showAppBar: true)},
      {'icon': Icons.chat, 'label': 'Support', 'page': const PatientSupportPage(showAppBar: true)},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) {
        final page = a['page'] as Widget;
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
                child: Icon(a['icon'] as IconData),
              ),
              const SizedBox(height: 5),
              Text(a['label'] as String, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList();
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildRow(Icons.edit_note, 'Prescription Updated', 'Dr. Wilson added new meds'),
      const SizedBox(height: 10),
      _buildRow(Icons.receipt_long, 'Payment Successful', 'Fee for Appointment #2940'),
    ]);
  }
  Widget _buildRow(IconData icon, String title, String sub) => Row(children: [
    Icon(icon, color: Colors.blue), const SizedBox(width: 15),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12))])
  ]);
}