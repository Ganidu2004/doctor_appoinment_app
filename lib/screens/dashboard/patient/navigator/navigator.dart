import 'package:appoinment_app/screens/dashboard/patient/account/patient_account.dart';
import 'package:appoinment_app/screens/dashboard/patient/appointments/patient_appointments_page.dart';
import 'package:appoinment_app/screens/dashboard/patient/doctor_find_page/find_doctor.dart';
import 'package:appoinment_app/screens/dashboard/patient/home_page.dart';
import 'package:appoinment_app/screens/dashboard/patient/navigator/footer.dart';
import 'package:appoinment_app/screens/dashboard/patient/navigator/header.dart';
import 'package:appoinment_app/screens/dashboard/patient/account/create_patient_account.dart';
import 'package:appoinment_app/screens/dashboard/patient/support/patient_support_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientMainLayout extends StatefulWidget {
  const PatientMainLayout({super.key});

  @override
  State<PatientMainLayout> createState() => _PatientMainLayoutState();
}

class _PatientMainLayoutState extends State<PatientMainLayout> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _hasCreatedAccount = false;
  String _patientName = "Sarah";

  @override
  void initState() {
    super.initState();
    _checkPatientAccount();
  }

  Future<void> _checkPatientAccount() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(user.uid)
            .get();

        if (mounted) {
          setState(() {
            _hasCreatedAccount = doc.exists;
            if (doc.exists && doc.data() != null) {
              final data = doc.data() as Map<String, dynamic>;
              _patientName = data['name'] ?? "Patient";
            }
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _hasCreatedAccount = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error checking patient account: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasCreatedAccount) {
      return PatientProfileCreatePage(
        onProfileCreated: () {
          setState(() {
            _isLoading = true;
          });
          _checkPatientAccount();
        },
      );
    }

    final List<Widget> pages = [
      const PatientHomePage(),
      const FindDoctorScreen(),
      const PatientAppointmentsPage(),
      const PatientSupportPage(),
      const PatientAccount(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PatientHeader(userName: _patientName),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: PatientFooter(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}