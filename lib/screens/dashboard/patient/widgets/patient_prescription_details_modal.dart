import 'package:flutter/material.dart';

class PatientPrescriptionDetailsModal extends StatelessWidget {
  final Map<String, dynamic> rxData;
  final String rxId;

  const PatientPrescriptionDetailsModal({
    super.key,
    required this.rxData,
    required this.rxId,
  });

  @override
  Widget build(BuildContext context) {
    final String doctorName = (rxData['doctorName'] ?? 'Dr. Specialist').toString();
    final String specialization = (rxData['specialization'] ?? 'Medical Specialist').toString();
    final String patientName = (rxData['patientName'] ?? 'Patient').toString();
    final String chiefComplaint = (rxData['chiefComplaint'] ?? 'N/A').toString();
    final String diagnosis = (rxData['diagnosis'] ?? 'N/A').toString();
    final String instructions = (rxData['instructions'] ?? 'Take medications as directed by physician. Adequate rest recommended.').toString();
    final String followUpDate = (rxData['followUpDate'] ?? 'N/A').toString();

    final vitals = rxData['vitals'] as Map<String, dynamic>? ?? {};
    final String bp = (vitals['bp'] ?? '120/80').toString();
    final String pulse = (vitals['pulse'] ?? '72').toString();
    final String temp = (vitals['temp'] ?? '98.6').toString();

    final List medications = rxData['medications'] as List? ?? [];
    final String rxNo = 'Rx-${rxId.length >= 6 ? rxId.substring(0, 6).toUpperCase() : rxId.toUpperCase()}';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rx Official Header Banner
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.history_edu_rounded, color: Color(0xFF0284C7), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctorName.startsWith('Dr.') ? doctorName : 'Dr. $doctorName',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            specialization,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Text(
                        rxNo,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 16),

                // Patient Info & Vitals Bar
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.person_rounded, size: 16, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Patient: $patientName',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Rx Issued', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue[700])),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildVitalChip('BP', '$bp mmHg'),
                            const SizedBox(width: 6),
                            _buildVitalChip('Pulse', '$pulse bpm'),
                            const SizedBox(width: 6),
                            _buildVitalChip('Temp', '$temp °F'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Clinical Diagnosis Impression Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CLINICAL DIAGNOSIS & IMPRESSION', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                      const SizedBox(height: 4),
                      Text('• Complaint: $chiefComplaint', style: const TextStyle(fontSize: 12.5, color: Color(0xFF78350F))),
                      Text('• Diagnosis: $diagnosis', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF78350F))),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Prescribed Medications Table
                Row(
                  children: [
                    const Icon(Icons.medication_liquid_rounded, size: 18, color: Color(0xFF0EA5E9)),
                    const SizedBox(width: 6),
                    Text(
                      'Prescribed Medications (${medications.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (medications.isEmpty)
                  const Text('No medications listed.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))
                else
                  ...medications.map((med) {
                    final Map<String, dynamic> mData = med is Map<String, dynamic> ? med : {};
                    final String mName = (mData['name'] ?? 'Medication').toString();
                    final String mDosage = (mData['dosage'] ?? '').toString();
                    final String mDuration = (mData['duration'] ?? '').toString();
                    final String mInstruction = (mData['instruction'] ?? '').toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF0F9FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.medication_rounded, size: 18, color: Color(0xFF0284C7)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(mName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                                const SizedBox(height: 2),
                                Text('Dosage: $mDosage • Duration: $mDuration', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                                if (mInstruction.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text('Instruction: $mInstruction', style: const TextStyle(fontSize: 11.5, color: Color(0xFF0284C7), fontWeight: FontWeight.w600)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 14),

                // Special Doctor Instructions
                const Text('DOCTOR\'S ADVICE & INSTRUCTIONS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text(instructions, style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.4)),
                const SizedBox(height: 12),

                // Follow-up Date Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 15, color: Color(0xFF0EA5E9)),
                      const SizedBox(width: 6),
                      Text('Recommended Follow-up Date: $followUpDate', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Close Rx Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVitalChip(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          Text(val, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}
