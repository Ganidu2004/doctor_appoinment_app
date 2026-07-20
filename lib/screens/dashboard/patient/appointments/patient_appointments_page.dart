import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:appoinment_app/services/notification_services.dart';
import '../doctor_find_page/find_doctor.dart';

class PatientAppointmentsPage extends StatefulWidget {
  final bool showAppBar;
  const PatientAppointmentsPage({super.key, this.showAppBar = false});

  @override
  State<PatientAppointmentsPage> createState() => _PatientAppointmentsPageState();
}

class _PatientAppointmentsPageState extends State<PatientAppointmentsPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Booked', 'Completed', 'Cancelled'];

  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
        'status': 'Cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      try {
        await NotificationService().showNotification(
          id: 401,
          title: 'Appointment Cancelled',
          body: 'Your appointment was cancelled successfully.',
        );
      } catch (err) {
        debugPrint('Notification error: $err');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Appointment cancelled successfully.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to cancel appointment: $error')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
        return Colors.blue;
      case 'cancelled':
        return Colors.red.shade700;
      case 'completed':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'LKR 0';
    final value = amount is num ? amount.toDouble() : double.tryParse(amount.toString()) ?? 0.0;
    return 'LKR ${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Please sign in to view your appointments.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              iconTheme: const IconThemeData(color: Colors.black),
              title: const Text(
                'My Appointments',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Filter Tabs
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.blue.shade50.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.blue.shade100.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
                  builder: (context, doctorsSnapshot) {
                    final Map<String, String> doctorImages = {};
                    if (doctorsSnapshot.hasData) {
                      for (var doc in doctorsSnapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        doctorImages[doc.id] = (data['profileImageUrl'] ?? data['imageUrl'] ?? '').toString();
                      }
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('appointments')
                          .where('patientUid', isEqualTo: user.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return _buildEmptyState();
                        }

                        var docs = snapshot.data!.docs;

                        // Apply filter
                        if (_selectedFilter != 'All') {
                          docs = docs.where((doc) {
                            final status = (doc.data() as Map<String, dynamic>)['status']?.toString() ?? '';
                            return status.toLowerCase() == _selectedFilter.toLowerCase();
                          }).toList();
                        }

                        if (docs.isEmpty) {
                          return _buildEmptyState();
                        }

                        final appointments = docs.toList()
                          ..sort((a, b) {
                            final aData = a.data() as Map<String, dynamic>;
                            final bData = b.data() as Map<String, dynamic>;
                            final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                            final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                            return bTime.compareTo(aTime);
                          });

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: appointments.length,
                          itemBuilder: (context, index) {
                            final doc = appointments[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final status = (data['status'] ?? 'Booked').toString();
                            final doctorId = data['doctorId'] ?? '';
                            final imageUrl = doctorImages[doctorId] ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF500CA4),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF500CA4).withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                    spreadRadius: 2,
                                  ),
                                ],
                                border: Border.all(color: const Color(0xFF500CA4).withValues(alpha: 0.2)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Material(
                                  color: Colors.transparent,
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent,
                                      iconTheme: const IconThemeData(color: Colors.white),
                                    ),
                                    child: ExpansionTile(
                                    iconColor: Colors.white,
                                    collapsedIconColor: Colors.white.withValues(alpha: 0.7),
                                    leading: CircleAvatar(
                                      radius: 26,
                                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                                      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                                      child: imageUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                                    ),
                                    title: Text(
                                      'Dr. ${data['doctorName'] ?? 'Doctor'}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['specialization'] ?? 'Specialist',
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 4,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.calendar_today, size: 12, color: Colors.white.withValues(alpha: 0.9)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  data['date'] ?? 'N/A',
                                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.access_time, size: 12, color: Colors.white.withValues(alpha: 0.9)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  data['time'] ?? 'N/A',
                                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.local_hospital, size: 12, color: Colors.white.withValues(alpha: 0.9)),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                data['hospitalName'] ?? 'Hospital/Clinic',
                                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Divider(height: 1, color: Colors.white.withValues(alpha: 0.3)),
                                            const SizedBox(height: 16),
                                            _buildDetailRow(Icons.calendar_today_outlined, 'Date', data['date'] ?? 'N/A'),
                                            const SizedBox(height: 10),
                                            _buildDetailRow(Icons.access_time_outlined, 'Time Slot', data['time'] ?? 'N/A'),
                                            const SizedBox(height: 10),
                                            _buildDetailRow(Icons.local_hospital_outlined, 'Hospital', data['hospitalName'] ?? 'N/A'),
                                            const SizedBox(height: 10),
                                            _buildDetailRow(Icons.medical_services_outlined, 'Reason', data['reason']?.toString().isNotEmpty == true ? data['reason'] : 'General Checkup'),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text('Charges', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _formatCurrency(data['consultationFee']),
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                                if (status.toLowerCase() != 'cancelled' && status.toLowerCase() != 'completed')
                                                  ElevatedButton.icon(
                                                    onPressed: () async {
                                                      final confirm = await showDialog<bool>(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                          title: const Text('Cancel Appointment?', style: TextStyle(fontWeight: FontWeight.bold)),
                                                          content: const Text('Are you sure you want to cancel this appointment? This action cannot be undone.'),
                                                          actions: [
                                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep Appointment')),
                                                            ElevatedButton(
                                                              onPressed: () => Navigator.pop(context, true),
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: Colors.redAccent,
                                                                elevation: 0,
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                              ),
                                                              child: const Text('Cancel It', style: TextStyle(color: Colors.white)),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (confirm == true) {
                                                        await _cancelAppointment(doc.id);
                                                      }
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.red[50],
                                                      foregroundColor: Colors.redAccent,
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                    ),
                                                    icon: const Icon(Icons.close, size: 16),
                                                    label: const Text('Cancel'),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.white),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_outlined, size: 64, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Appointments Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'All'
                  ? 'Book a doctor to see your upcoming visits here.'
                  : 'You have no appointments with status "$_selectedFilter".',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FindDoctorScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Find a Doctor', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
