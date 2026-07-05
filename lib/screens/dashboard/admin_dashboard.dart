import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      // මෙතැනදී streams ඒකාබද්ධ කර එක StreamBuilder එකක් භාවිතා කිරීම වඩාත් කාර්යක්ෂමයි
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('patients').snapshots(),
        builder: (context, patientsSnapshot) {
          if (!patientsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final totalPatients = patientsSnapshot.data?.docs.length ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    // Total Patients Card (Clickable)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PatientListPage()),
                        );
                      },
                      child: _buildStatCard('Total Patients', totalPatients.toString(), Colors.blue),
                    ),
                    // අනෙකුත් Stats මෙහි එක් කරන්න...
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return SizedBox(
      width: 172,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// Patient List Page
class PatientListPage extends StatelessWidget {
  const PatientListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Patients")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('patients').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var patient = snapshot.data!.docs[index];
              return ListTile(
                leading: CircleAvatar(child: Text(patient['name'][0])),
                title: Text(patient['name'] ?? 'No Name'),
                subtitle: Text(patient['email'] ?? 'No Email'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.block, color: Colors.orange), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {}),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}