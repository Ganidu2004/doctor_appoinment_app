import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorBillingPage extends StatelessWidget {
  const DoctorBillingPage({super.key});

  String _formatCurrency(double amount) {
    return 'LKR ${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view billing information.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('payments').where('doctorId', isEqualTo: user.uid).orderBy('paymentDate', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No payment history available yet. Your completed appointment payments will appear here.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final payments = snapshot.data!.docs;
        double totalAmount = 0;
        double totalHospitalCharges = 0;

        for (final doc in payments) {
          final data = doc.data() as Map<String, dynamic>;
          totalAmount += (data['amount'] is num ? (data['amount'] as num).toDouble() : double.tryParse(data['amount']?.toString() ?? '0') ?? 0);
          totalHospitalCharges += (data['hospitalCharges'] is num ? (data['hospitalCharges'] as num).toDouble() : double.tryParse(data['hospitalCharges']?.toString() ?? '0') ?? 0);
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment & Billing', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatCurrency(totalAmount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Total received', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hospital Charges', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text(_formatCurrency(totalHospitalCharges), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                        child: const Text('Updated', style: TextStyle(color: Colors.blue)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: payments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = payments[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['paymentStatus']?.toString() ?? 'Unknown';
                  final date = data['paymentDate'] is Timestamp ? (data['paymentDate'] as Timestamp).toDate() : DateTime.now();

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      title: Text(_formatCurrency((data['amount'] is num ? (data['amount'] as num).toDouble() : double.tryParse(data['amount']?.toString() ?? '0') ?? 0)), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Method: ${data['paymentMethod'] ?? 'Unknown'}'),
                          Text('Status: $status'),
                          Text('Hospital charges: ${_formatCurrency((data['hospitalCharges'] is num ? (data['hospitalCharges'] as num).toDouble() : double.tryParse(data['hospitalCharges']?.toString() ?? '0') ?? 0))}'),
                          Text('Date: ${date.toLocal().toString().split('.').first}'),
                        ],
                      ),
                      trailing: Text(status, style: TextStyle(color: status.toLowerCase() == 'pending' ? Colors.orange : Colors.green)),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
