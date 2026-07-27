import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorConsultationQueueModal extends StatefulWidget {
  const DoctorConsultationQueueModal({super.key});

  @override
  State<DoctorConsultationQueueModal> createState() => _DoctorConsultationQueueModalState();
}

class _DoctorConsultationQueueModalState extends State<DoctorConsultationQueueModal> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle & title header
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
                    Icon(Icons.people_alt_rounded, color: Color(0xFF10B981), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Live Consultation Queue',
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

          // Stream of Queue Items
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('doctorId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                }

                final docs = snapshot.data?.docs ?? [];

                final queueItems = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '').toString().toLowerCase();
                  return status == 'confirmed' || status == 'in_consultation' || status == 'waiting' || status == 'scheduled';
                }).toList();

                if (queueItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.airline_seat_recline_normal_rounded, size: 40, color: Color(0xFF10B981)),
                        ),
                        const SizedBox(height: 14),
                        const Text('Queue Empty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        const Text('No patients currently waiting in the consultation room.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: queueItems.length,
                  itemBuilder: (context, index) {
                    final doc = queueItems[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final String patientName = (data['patientName'] ?? 'Patient').toString();
                    final String time = (data['time'] ?? '09:00 AM').toString();
                    final String queueToken = '#${(index + 1).toString().padLeft(2, '0')}';
                    final String queueStatus = (data['queueStatus'] ?? data['status'] ?? 'Waiting').toString();
                    final bool isInRoom = queueStatus.toLowerCase() == 'in_consultation';
                    final bool isNext = index == 0 && !isInRoom;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isInRoom
                              ? const Color(0xFF10B981)
                              : isNext
                                  ? const Color(0xFF0EA5E9)
                                  : const Color(0xFFE2E8F0),
                          width: isInRoom || isNext ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Token Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isInRoom
                                      ? const Color(0xFFECFDF5)
                                      : isNext
                                          ? const Color(0xFFE0F2FE)
                                          : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  queueToken,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: isInRoom
                                        ? const Color(0xFF047857)
                                        : isNext
                                            ? const Color(0xFF0284C7)
                                            : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                                    const SizedBox(height: 2),
                                    Text('Scheduled: $time • In-Clinic Consultation', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),

                              // Status Tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isInRoom
                                      ? const Color(0xFFECFDF5)
                                      : isNext
                                          ? const Color(0xFFE0F2FE)
                                          : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isInRoom
                                        ? const Color(0xFFA7F3D0)
                                        : isNext
                                            ? const Color(0xFFBAE6FD)
                                            : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  isInRoom
                                      ? 'In Room 🩺'
                                      : isNext
                                          ? 'Next Up ⏳'
                                          : 'Waiting 🪑',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isInRoom
                                        ? const Color(0xFF047857)
                                        : isNext
                                            ? const Color(0xFF0284C7)
                                            : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Call In & Complete Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('appointments').doc(doc.id).update({'queueStatus': 'in_consultation'});
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Called in $patientName! 📢'), backgroundColor: const Color(0xFF10B981)),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.record_voice_over_rounded, size: 16, color: Colors.white),
                                  label: const Text('Call In Patient 📢', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('appointments').doc(doc.id).update({'status': 'completed', 'queueStatus': 'completed'});
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Completed consultation for $patientName! 📝'), backgroundColor: const Color(0xFF0EA5E9)),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF0EA5E9)),
                                  label: const Text('Complete 📝', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9))),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF0EA5E9)),
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
}
