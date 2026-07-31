import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorPatientAnalyticsModal extends StatelessWidget {
  const DoctorPatientAnalyticsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const SizedBox(
              height: 320,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9))),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // Analytics Computation
          final Set<String> allPatientIds = {};
          final Map<String, int> patientVisitCounts = {};
          int completedCount = 0;
          int pendingCount = 0;
          int cancelledCount = 0;

          int morningVisits = 0;
          int afternoonVisits = 0;
          int eveningVisits = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final pUid = (data['patientUid'] ?? data['patientName'] ?? '').toString();
            final status = (data['status'] ?? '').toString().toLowerCase();

            if (pUid.isNotEmpty) {
              allPatientIds.add(pUid);
              patientVisitCounts[pUid] = (patientVisitCounts[pUid] ?? 0) + 1;
            }

            if (status.contains('complet')) {
              completedCount++;
            } else if (status.contains('cancel')) {
              cancelledCount++;
            } else {
              pendingCount++;
            }

            // Time slot distribution analysis
            final timeStr = (data['time'] ?? '').toString().toUpperCase();
            if (timeStr.contains('AM')) {
              morningVisits++;
            } else if (timeStr.contains('PM')) {
              final hourMatch = RegExp(r'(\d+):').firstMatch(timeStr);
              if (hourMatch != null) {
                final hour = int.tryParse(hourMatch.group(1)!) ?? 12;
                if (hour == 12 || hour < 4) {
                  afternoonVisits++;
                } else {
                  eveningVisits++;
                }
              } else {
                eveningVisits++;
              }
            } else {
              morningVisits++;
            }
          }

          final totalUniquePatients = allPatientIds.length;

          int newPatients = 0;
          int returningPatients = 0;
          patientVisitCounts.forEach((_, visitCount) {
            if (visitCount == 1) {
              newPatients++;
            } else {
              returningPatients++;
            }
          });

          final totalCountedPatients = newPatients + returningPatients;
          final double newPct = totalCountedPatients > 0 ? (newPatients / totalCountedPatients) : 0.0;
          final double returningPct = totalCountedPatients > 0 ? (returningPatients / totalCountedPatients) : 0.0;

          int newFlex = (newPct * 100).round();
          int returningFlex = (returningPct * 100).round();

          if (totalCountedPatients > 0 && newFlex == 0 && returningFlex == 0) {
            newFlex = 50;
            returningFlex = 50;
          } else if (totalCountedPatients == 0) {
            newFlex = 50;
            returningFlex = 50;
          }

          // Peak hours determination
          String peakSlotName = 'Evening (04:00 PM - 09:00 PM)';
          int peakVisits = eveningVisits;

          if (morningVisits >= afternoonVisits && morningVisits >= eveningVisits && morningVisits > 0) {
            peakSlotName = 'Morning (08:00 AM - 12:00 PM)';
            peakVisits = morningVisits;
          } else if (afternoonVisits >= morningVisits && afternoonVisits >= eveningVisits && afternoonVisits > 0) {
            peakSlotName = 'Afternoon (12:00 PM - 04:00 PM)';
            peakVisits = afternoonVisits;
          }

          final totalTimeVisits = morningVisits + afternoonVisits + eveningVisits;
          final peakPct = totalTimeVisits > 0 ? ((peakVisits / totalTimeVisits) * 100).toStringAsFixed(0) : '0';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.analytics_rounded, color: Color(0xFF0284C7), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Statistics & Insights',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Live metrics based on consultation logs',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. Total Patients Summary Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Patients Registered',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalUniquePatients Patient${totalUniquePatients == 1 ? '' : 's'}',
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$completedCount completed consultation${completedCount == 1 ? '' : 's'}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. New vs. Returning Patients Breakdown
                const Text('New vs. Returning Patients', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF0EA5E9), shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text('New Patients (${(newPct * 100).toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            ],
                          ),
                          Row(
                            children: [
                              Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text('Returning (${(returningPct * 100).toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 12,
                          child: Row(
                            children: [
                              Expanded(
                                flex: newFlex,
                                child: Container(color: newPct > 0 ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0)),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                flex: returningFlex,
                                child: Container(color: returningPct > 0 ? const Color(0xFF10B981) : const Color(0xFFCBD5E1)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$newPatients First-time Visit${newPatients == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          Text('$returningPatients Repeat Consultation${returningPatients == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Peak Consultation Hours
                const Text('Peak Consultation Hours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.access_time_filled_rounded, color: Color(0xFFB45309), size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Highest Patient Traffic', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB45309),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('$peakPct% Peak', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              peakSlotName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              totalTimeVisits > 0
                                  ? 'Most appointment bookings occur during this shift window.'
                                  : 'No appointment logs recorded yet for peak analysis.',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Consultation Status Breakdown Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Column(
                          children: [
                            Text('$completedCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF047857))),
                            const Text('Completed', style: TextStyle(fontSize: 11, color: Color(0xFF065F46))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Column(
                          children: [
                            Text('$pendingCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFB45309))),
                            const Text('Pending/Booked', style: TextStyle(fontSize: 11, color: Color(0xFF92400E))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Column(
                          children: [
                            Text('$cancelledCount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent)),
                            const Text('Cancelled', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
