import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Stream<QuerySnapshot> get doctorsStream => FirebaseFirestore.instance.collection('doctors').snapshots();
  Stream<QuerySnapshot> get patientsStream => FirebaseFirestore.instance.collection('patients').snapshots();
  Stream<QuerySnapshot> get appointmentsStream => FirebaseFirestore.instance.collection('appointments').snapshots();
  Stream<QuerySnapshot> get paymentsStream => FirebaseFirestore.instance.collection('payments').snapshots();

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
      case 'pending':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: appointmentsStream,
        builder: (context, appointmentsSnapshot) {
          if (appointmentsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointmentDocs = appointmentsSnapshot.data?.docs ?? [];
          final totalAppointments = appointmentDocs.length;
          final pendingAppointments = appointmentDocs.where((doc) {
            final status = (doc['status'] ?? '').toString().toLowerCase();
            return status == 'booked' || status == 'pending';
          }).length;
          final completedAppointments = appointmentDocs.where((doc) => (doc['status'] ?? '').toString().toLowerCase() == 'completed').length;
          final cancelledAppointments = appointmentDocs.where((doc) => (doc['status'] ?? '').toString().toLowerCase() == 'cancelled').length;
          final todayAppointments = appointmentDocs.where((doc) {
            final date = (doc['date'] ?? '').toString();
            final today = DateTime.now();
            final todayStr = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
            return date.contains(todayStr);
          }).length;

          return StreamBuilder<QuerySnapshot>(
            stream: paymentsStream,
            builder: (context, paymentsSnapshot) {
              if (paymentsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final paymentDocs = paymentsSnapshot.data?.docs ?? [];
              double totalRevenue = 0;
              double totalHospitalCharges = 0;
              for (final doc in paymentDocs) {
                final data = doc.data() as Map<String, dynamic>;
                totalRevenue += data['amount'] is num ? (data['amount'] as num).toDouble() : double.tryParse(data['amount']?.toString() ?? '0') ?? 0;
                totalHospitalCharges += data['hospitalCharges'] is num ? (data['hospitalCharges'] as num).toDouble() : double.tryParse(data['hospitalCharges']?.toString() ?? '0') ?? 0;
              }

              return StreamBuilder<QuerySnapshot>(
                stream: doctorsStream,
                builder: (context, doctorsSnapshot) {
                  if (doctorsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final totalDoctors = doctorsSnapshot.data?.docs.length ?? 0;

                  return StreamBuilder<QuerySnapshot>(
                    stream: patientsStream,
                    builder: (context, patientsSnapshot) {
                      if (patientsSnapshot.connectionState == ConnectionState.waiting) {
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
                                _buildStatCard('Total Patients', totalPatients.toString(), Colors.blue),
                                _buildStatCard('Total Doctors', totalDoctors.toString(), Colors.blueAccent),
                                _buildStatCard('Total Appointments', totalAppointments.toString(), Colors.indigo),
                                _buildStatCard('Pending', pendingAppointments.toString(), Colors.orange),
                                _buildStatCard('Completed', completedAppointments.toString(), Colors.green),
                                _buildStatCard('Cancelled', cancelledAppointments.toString(), Colors.red),
                                _buildStatCard('Today', todayAppointments.toString(), Colors.teal),
                                _buildStatCard('Revenue', 'LKR ${_formatAmount(totalRevenue)}', Colors.green.shade700),
                                _buildStatCard('Hospital Charges', 'LKR ${_formatAmount(totalHospitalCharges)}', Colors.purple.shade700),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text('Recent Appointments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ...appointmentDocs.take(6).map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final status = (data['status'] ?? 'Unknown').toString();
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(data['doctorName'] ?? 'Doctor'),
                                  subtitle: Text('${data['patientName'] ?? 'Patient'} • ${data['date'] ?? ''} • ${data['time'] ?? ''}'),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor(status).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(status, style: TextStyle(color: statusColor(status), fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
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
