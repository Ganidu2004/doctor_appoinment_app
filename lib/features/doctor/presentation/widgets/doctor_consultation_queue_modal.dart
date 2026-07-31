import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorConsultationQueueModal extends StatefulWidget {
  const DoctorConsultationQueueModal({super.key});

  @override
  State<DoctorConsultationQueueModal> createState() => _DoctorConsultationQueueModalState();
}

class _DoctorConsultationQueueModalState extends State<DoctorConsultationQueueModal> {
  String _selectedCategory = 'all'; // 'all', 'online', 'in_person'

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
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.groups_rounded, color: Color(0xFF10B981), size: 24),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Consultation Queue',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Real-time waiting room & patient queue',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
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
          
          // Filter Tabs (All, Online Video, In-Person Clinic)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _buildFilterTab('all', 'All Queue', Icons.format_list_bulleted_rounded),
                  _buildFilterTab('online', 'Online 📹', Icons.videocam_rounded),
                  _buildFilterTab('in_person', 'In-Clinic 🏥', Icons.local_hospital_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Stream of Queue Items
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('doctorId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                }

                final docs = snapshot.data?.docs ?? [];

                // Filter items for queue
                final queueItems = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '').toString().toLowerCase();
                  final queueStatus = (data['queueStatus'] ?? '').toString().toLowerCase();

                  final bool isActiveInQueue = status == 'booked' ||
                      status == 'scheduled' ||
                      status == 'confirmed' ||
                      status == 'pending' ||
                      queueStatus == 'waiting' ||
                      queueStatus == 'in_consultation';

                  if (!isActiveInQueue) return false;

                  final cType = (data['consultationType'] ?? '').toString().toLowerCase();
                  if (_selectedCategory == 'online') {
                    return cType.contains('online') || cType.contains('video') || cType.contains('virtual');
                  } else if (_selectedCategory == 'in_person') {
                    return cType.contains('person') || cType.contains('clinic') || cType.contains('hospital') || cType.isEmpty;
                  }

                  return true;
                }).toList();

                // Sort in-consultation first, then by tokenNumber ascending
                queueItems.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aIn = (aData['queueStatus'] ?? '').toString().toLowerCase() == 'in_consultation';
                  final bIn = (bData['queueStatus'] ?? '').toString().toLowerCase() == 'in_consultation';
                  if (aIn && !bIn) return -1;
                  if (!aIn && bIn) return 1;

                  final aToken = (aData['tokenNumber'] is num) ? (aData['tokenNumber'] as num).toInt() : 999;
                  final bToken = (bData['tokenNumber'] is num) ? (bData['tokenNumber'] as num).toInt() : 999;
                  return aToken.compareTo(bToken);
                });

                if (queueItems.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Color(0xFFECFDF5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.airline_seat_recline_normal_rounded, size: 44, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Queue Empty',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedCategory == 'online'
                                ? 'No patients currently waiting in the online video room.'
                                : _selectedCategory == 'in_person'
                                    ? 'No patients currently waiting in the in-clinic room.'
                                    : 'No patients currently waiting in the consultation room.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
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
                    final String date = (data['date'] ?? 'Today').toString();
                    final String queueToken = (data['queueToken'] != null && data['queueToken'].toString().isNotEmpty)
                        ? data['queueToken'].toString()
                        : (data['tokenNumber'] != null)
                            ? '#${data['tokenNumber'].toString().padLeft(2, '0')}'
                            : '#${(index + 1).toString().padLeft(2, '0')}';
                    final String queueStatus = (data['queueStatus'] ?? data['status'] ?? 'Waiting').toString();
                    final String cType = (data['consultationType'] ?? 'In-Person Clinic Visit').toString();
                    final bool isOnline = cType.toLowerCase().contains('online') || cType.toLowerCase().contains('video');

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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                    Text(
                                      patientName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          isOnline ? Icons.videocam_rounded : Icons.local_hospital_rounded,
                                          size: 13,
                                          color: isOnline ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '$date • $time (${isOnline ? 'Online Video' : 'In-Clinic'})',
                                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
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
                                    await FirebaseFirestore.instance.collection('appointments').doc(doc.id).update({
                                      'queueStatus': 'in_consultation',
                                    });
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isOnline
                                                ? 'Joined Live Video Call with $patientName! 📹'
                                                : 'Called in $patientName! 📢',
                                          ),
                                          backgroundColor: const Color(0xFF10B981),
                                        ),
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    isOnline ? Icons.videocam_rounded : Icons.record_voice_over_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    isOnline ? 'Start Video Call 📹' : 'Call In Patient 📢',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isOnline ? const Color(0xFF059669) : const Color(0xFF10B981),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('appointments').doc(doc.id).update({
                                      'status': 'completed',
                                      'queueStatus': 'completed',
                                    });
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Completed consultation for $patientName! 📝'),
                                          backgroundColor: const Color(0xFF0EA5E9),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF0EA5E9)),
                                  label: const Text('Complete 📝', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9))),
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

  Widget _buildFilterTab(String categoryKey, String label, IconData icon) {
    final bool isSelected = _selectedCategory == categoryKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = categoryKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
