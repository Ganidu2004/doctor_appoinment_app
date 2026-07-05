import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- MAIN DASHBOARD PAGE ---
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
            onPressed: () async => await FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('patients').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final totalPatients = snapshot.data!.docs.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PatientListPage()),
                    );
                  },
                  child: _buildStatCard('Total Patients', totalPatients.toString(), Colors.blue),
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

// --- PATIENT LIST PAGE ---
class PatientListPage extends StatelessWidget {
  const PatientListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient List")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('patients').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final patients = snapshot.data!.docs;

          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              var patient = patients[index];
              var data = patient.data() as Map<String, dynamic>;
              
              return PatientCard(
                uid: patient.id,
                name: data['name'] ?? 'No Name',
                email: data['email'] ?? 'No Email',
                profileImageUrl: data['profileImageUrl'] ?? '',
              );
            },
          );
        },
      ),
    );
  }
}

// --- PATIENT CARD COMPONENT ---
class PatientCard extends StatelessWidget {
  final String uid, name, email, profileImageUrl;

  const PatientCard({
    super.key, 
    required this.uid, 
    required this.name, 
    required this.email, 
    required this.profileImageUrl
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[200],
          backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
          child: profileImageUrl.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Text(name),
        subtitle: Text(email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.block, color: Colors.orange),
              onPressed: () => FirebaseFirestore.instance.collection('patients').doc(uid).update({'isBlocked': true}),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => FirebaseFirestore.instance.collection('patients').doc(uid).delete(),
            ),
          ],
        ),
      ),
    );
  }
}