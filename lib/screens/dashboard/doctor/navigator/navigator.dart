import 'package:appoinment_app/screens/dashboard/doctor/account/create_doctor_account.dart';
import 'package:appoinment_app/screens/dashboard/doctor/account/doctor_account.dart';
import 'package:appoinment_app/screens/dashboard/doctor/messages/doctor_messages_page.dart';
import 'package:appoinment_app/screens/dashboard/doctor/navigator/header.dart';
import 'package:appoinment_app/screens/dashboard/doctor/home_page.dart';
import 'package:appoinment_app/screens/dashboard/doctor/navigator/footer.dart';
import 'package:appoinment_app/screens/dashboard/doctor/patients/doctor_patients_page.dart';
import 'package:appoinment_app/screens/dashboard/doctor/shedul/doctor_shedul.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _hasCreatedAccount = false;
  
  Map<String, dynamic> _allDoctorData = {};

  final List<String> _titles = [
    'Doctor Dashboard',
    'Doctor Schedule',
    'Patients List',
    'Messages',
    'Settings'
  ];

  @override
  void initState() {
    super.initState();
    _checkDoctorAccount();
  }

  Future<void> _checkDoctorAccount() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(user.uid)
            .get();

        if (mounted) {
          setState(() {
            _hasCreatedAccount = doc.exists;
            if (doc.exists && doc.data() != null) {
              _allDoctorData = doc.data() as Map<String, dynamic>;
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error checking doctor account: $e");
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasCreatedAccount) {
      return DoctorProfileCreatePage(
        onProfileCreated: () {
          setState(() {
            _isLoading = true;
          });
          _checkDoctorAccount();
        },
      );
    }

    final List<Widget> pages = [
      DoctorHomePage(doctorData: _allDoctorData), 
      const MySchedulePage(),
      const DoctorPatientsPage(),
      const DoctorMessagesPage(),
      const SettingsProfilePage(), 
    ];

    return Scaffold(
      appBar: CustomHeader(title: _titles[_selectedIndex]),
      
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      bottomNavigationBar: CustomFooter(
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