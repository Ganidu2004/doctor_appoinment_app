import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PatientPaymentHistoryPage extends StatelessWidget {
  const PatientPaymentHistoryPage({super.key});

  String _formatCurrency(double amount) {
    return 'LKR ${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view your payment history.'));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Payment History', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .where('patientId', isEqualTo: user.uid)
            .orderBy('paymentDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No payment records found yet. Your completed appointment payments will appear here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final payments = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = payments[index].data() as Map<String, dynamic>;
              final amount = (data['amount'] is num ? (data['amount'] as num).toDouble() : double.tryParse(data['amount']?.toString() ?? '0') ?? 0);
              final hospitalCharges = (data['hospitalCharges'] is num ? (data['hospitalCharges'] as num).toDouble() : double.tryParse(data['hospitalCharges']?.toString() ?? '0') ?? 0);
              final status = data['paymentStatus']?.toString() ?? 'Unknown';
              final method = data['paymentMethod']?.toString() ?? 'Unknown';
              final date = data['paymentDate'] is Timestamp ? (data['paymentDate'] as Timestamp).toDate() : DateTime.now();

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatCurrency(amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            decoration: BoxDecoration(
                              color: status.toLowerCase() == 'pending' ? Colors.orange.shade100 : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Text(status, style: TextStyle(color: status.toLowerCase() == 'pending' ? Colors.orange.shade700 : Colors.green.shade700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Method: $method'),
                      Text('Hospital charges: ${_formatCurrency(hospitalCharges)}'),
                      Text('Date: ${date.toLocal().toString().split('.').first}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
