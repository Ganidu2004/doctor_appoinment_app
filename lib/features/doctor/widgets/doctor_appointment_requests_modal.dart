import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DoctorAppointmentRequestsModal extends StatefulWidget {
  const DoctorAppointmentRequestsModal({super.key});

  @override
  State<DoctorAppointmentRequestsModal> createState() => _DoctorAppointmentRequestsModalState();
}

class _DoctorAppointmentRequestsModalState extends State<DoctorAppointmentRequestsModal> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pending_actions_rounded, color: Color(0xFF0EA5E9), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Appointment Requests',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Stream Builder of Pending & Scheduled Requests
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('doctorId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)));
                }

                final docs = snapshot.data?.docs ?? [];

                final requests = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '').toString().toLowerCase();
                  return status == 'pending' || status == 'requested' || status == 'scheduled';
                }).toList();

                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_outline_rounded, size: 40, color: Color(0xFF10B981)),
                        ),
                        const SizedBox(height: 14),
                        const Text('No Pending Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        const Text('All patient appointment requests have been processed.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final doc = requests[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final String patientName = (data['patientName'] ?? 'Patient').toString();
                    final String date = (data['date'] ?? 'Today').toString();
                    final String time = (data['time'] ?? '09:00 AM').toString();
                    final String hospital = (data['hospitalName'] ?? data['hospital'] ?? 'Clinic').toString();
                    final String status = (data['status'] ?? 'Pending').toString();
                    final String symptoms = (data['notes'] ?? data['reason'] ?? 'General Consultation').toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFFE0F2FE),
                                child: Text(
                                  patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                                  style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                                    const SizedBox(height: 2),
                                    Text('$date • $time', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF0EA5E9)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text('Reason/Symptoms: $symptoms • $hospital', style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 3 Action Buttons: Accept, Reschedule, Cancel
                          Row(
                            children: [
                              // Accept Button
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('appointments').doc(doc.id).update({'status': 'confirmed'});
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Appointment accepted successfully! ✅'), backgroundColor: Color(0xFF10B981)),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                                  label: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Reschedule Button
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showRescheduleDialog(context, doc.id, date, time),
                                  icon: const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF0EA5E9)),
                                  label: const Text('Reschedule', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9))),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF0EA5E9)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Cancel Button
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('appointments').doc(doc.id).update({'status': 'cancelled'});
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Appointment cancelled.'), backgroundColor: Color(0xFFEF4444)),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.cancel_rounded, size: 16, color: Color(0xFFEF4444)),
                                  label: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFEF4444)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context, String docId, String currentDate, String currentTime) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reschedule Appointment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Select New Date'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today_rounded, color: Color(0xFF0EA5E9)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Select New Time'),
                    subtitle: Text(selectedTime.format(context)),
                    trailing: const Icon(Icons.access_time_rounded, color: Color(0xFF0EA5E9)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
                    final newTimeStr = selectedTime.format(context);

                    await FirebaseFirestore.instance.collection('appointments').doc(docId).update({
                      'date': newDateStr,
                      'time': newTimeStr,
                      'status': 'rescheduled',
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Rescheduled to $newDateStr at $newTimeStr 🗓️'), backgroundColor: const Color(0xFF0EA5E9)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9)),
                  child: const Text('Confirm Reschedule', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
