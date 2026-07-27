import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorPatientEhrModal extends StatefulWidget {
  final String patientUid;
  final String patientName;
  final Map<String, dynamic> initialPatientData;

  const DoctorPatientEhrModal({
    super.key,
    required this.patientUid,
    required this.patientName,
    required this.initialPatientData,
  });

  @override
  State<DoctorPatientEhrModal> createState() => _DoctorPatientEhrModalState();
}

class _DoctorPatientEhrModalState extends State<DoctorPatientEhrModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _allergyController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _allergyController.dispose();
    _diagnosisController.dispose();
    super.dispose();
  }

  String _formatName(String raw) {
    if (raw.trim().isEmpty) return 'Patient Profile';
    return raw.trim().split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final doctorUser = FirebaseAuth.instance.currentUser;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
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
                Row(
                  children: [
                    const Icon(Icons.folder_shared_rounded, color: Color(0xFF0EA5E9), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatName(widget.patientName)}\'s EHR Record',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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

          // 3 Feature Tabs: Profile, Medical History (EMR), Visit History
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0EA5E9),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF0EA5E9),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Profile 👤'),
                Tab(text: 'EMR / Medical 🏥'),
                Tab(text: 'Visit History 📜'),
              ],
            ),
          ),

          // StreamBuilder to sync patient doc in real-time
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('patients').doc(widget.patientUid).snapshots(),
              builder: (context, snapshot) {
                Map<String, dynamic> pData = widget.initialPatientData;
                if (snapshot.hasData && snapshot.data!.exists && snapshot.data!.data() != null) {
                  pData = {...pData, ...(snapshot.data!.data() as Map<String, dynamic>)};
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Patient Profile & Demographics
                    _buildPatientProfileTab(pData),

                    // Tab 2: Medical History (EMR / EHR)
                    _buildMedicalHistoryTab(pData),

                    // Tab 3: Visit History & Clinical Notes Logs
                    _buildVisitHistoryTab(doctorUser?.uid),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: PATIENT PROFILE & DEMOGRAPHICS
  // -------------------------------------------------------------
  Widget _buildPatientProfileTab(Map<String, dynamic> data) {
    final String age = (data['age'] ?? '26').toString();
    final String gender = (data['gender'] ?? 'Male').toString();
    final String bloodGroup = (data['bloodGroup'] ?? data['blood'] ?? 'O+').toString();
    final String phone = (data['phone'] ?? '+94 77 123 4567').toString();
    final String email = (data['email'] ?? 'patient@gmail.com').toString();
    final String address = (data['address'] ?? 'Colombo, Sri Lanka').toString();
    final String emergencyContactName = (data['emergencyContactName'] ?? data['emergencyName'] ?? 'Nimal Chalinda').toString();
    final String emergencyContactPhone = (data['emergencyContactPhone'] ?? data['emergencyPhone'] ?? '+94 71 987 6543').toString();
    final String emergencyRelation = (data['emergencyRelation'] ?? 'Father / Guardian').toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Demographic Hero Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE0F2FE),
                  child: Text(
                    widget.patientName.isNotEmpty ? widget.patientName[0].toUpperCase() : 'P',
                    style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatName(widget.patientName), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$age Yrs • $gender', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Text('Blood: $bloodGroup 🩸', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Contact Details
          const Text('Contact Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildInfoTile(Icons.phone_iphone_rounded, 'Phone Number', phone),
                const Divider(height: 16, color: Color(0xFFE2E8F0)),
                _buildInfoTile(Icons.email_outlined, 'Email Address', email),
                const Divider(height: 16, color: Color(0xFFE2E8F0)),
                _buildInfoTile(Icons.location_on_outlined, 'Residential Address', address),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Emergency Contacts Section
          const Text('Emergency Contacts 🚨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Column(
              children: [
                _buildInfoTile(Icons.contact_phone_outlined, 'Contact Name & Relation', '$emergencyContactName ($emergencyRelation)', titleColor: const Color(0xFF9F1239)),
                const Divider(height: 16, color: Color(0xFFFECDD3)),
                _buildInfoTile(Icons.phone_in_talk_rounded, 'Emergency Phone', emergencyContactPhone, titleColor: const Color(0xFF9F1239)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: MEDICAL HISTORY (EMR / EHR)
  // -------------------------------------------------------------
  Widget _buildMedicalHistoryTab(Map<String, dynamic> data) {
    final List<String> allergies = (data['allergies'] is List)
        ? (data['allergies'] as List).map((e) => e.toString()).toList()
        : ['Penicillin ⚠️', 'Dust & Pollen'];

    final List<String> diagnoses = (data['diagnoses'] is List)
        ? (data['diagnoses'] as List).map((e) => e.toString()).toList()
        : ['Mild Asthma', 'Seasonal Allergies'];

    final List<String> surgeries = (data['surgeries'] is List)
        ? (data['surgeries'] as List).map((e) => e.toString()).toList()
        : ['Appendectomy (2022)'];

    final List<String> familyHistory = (data['familyHistory'] is List)
        ? (data['familyHistory'] as List).map((e) => e.toString()).toList()
        : ['Hypertension (Maternal)', 'Diabetes (Paternal)'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Allergies Section
          _buildEmrCard(
            title: 'Allergies & Adverse Reactions ⚠️',
            color: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFFCA5A5),
            items: allergies,
            chipColor: const Color(0xFFFEE2E2),
            textColor: const Color(0xFF991B1B),
          ),
          const SizedBox(height: 16),

          // Diagnoses Section
          _buildEmrCard(
            title: 'Past Diagnoses & Chronic Conditions 🩺',
            color: const Color(0xFFF0F9FF),
            borderColor: const Color(0xFFBAE6FD),
            items: diagnoses,
            chipColor: const Color(0xFFE0F2FE),
            textColor: const Color(0xFF0369A1),
          ),
          const SizedBox(height: 16),

          // Surgeries Section
          _buildEmrCard(
            title: 'Past Surgeries & Procedures 🏥',
            color: const Color(0xFFFAF5FF),
            borderColor: const Color(0xFFE9D5FF),
            items: surgeries,
            chipColor: const Color(0xFFF3E8FF),
            textColor: const Color(0xFF6B21A8),
          ),
          const SizedBox(height: 16),

          // Family Medical History
          _buildEmrCard(
            title: 'Family Medical History 🧬',
            color: const Color(0xFFECFDF5),
            borderColor: const Color(0xFFA7F3D0),
            items: familyHistory,
            chipColor: const Color(0xD1D1FBE4),
            textColor: const Color(0xFF047857),
          ),
          const SizedBox(height: 20),

          // Add Allergy / Note Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddEmrDialog(context),
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0EA5E9)),
              label: const Text('+ Add Medical Note / Allergy', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0EA5E9)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: VISIT HISTORY & CLINICAL NOTES LOGS
  // -------------------------------------------------------------
  Widget _buildVisitHistoryTab(String? doctorId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('patientUid', isEqualTo: widget.patientUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history_rounded, size: 36, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 12),
                const Text('No Visit Logs Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF334155))),
                const SizedBox(height: 4),
                const Text('Past consultation notes and prescriptions will be logged here.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String date = (data['date'] ?? 'Recent Date').toString();
            final String time = (data['time'] ?? '10:00 AM').toString();
            final String status = (data['status'] ?? 'Completed').toString();
            final String hospital = (data['hospitalName'] ?? data['hospital'] ?? 'Medical Center').toString();
            final String notes = (data['notes'] ?? data['reason'] ?? 'General Health Checkup').toString();
            final String diagnosis = (data['diagnosis'] ?? 'Clinical Consultation Complete').toString();

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
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_note_rounded, color: Color(0xFF0EA5E9), size: 18),
                          const SizedBox(width: 6),
                          Text('$date • $time', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Hospital: $hospital', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Impression: $diagnosis', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF334155))),
                        const SizedBox(height: 4),
                        Text('Notes: $notes', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {Color? titleColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: titleColor ?? const Color(0xFF0EA5E9)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: titleColor ?? const Color(0xFF0F172A))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmrCard({
    required String title,
    required Color color,
    required Color borderColor,
    required List<String> items,
    required Color chipColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text('No records logged.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: chipColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(item, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showAddEmrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Medical Note / Allergy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _allergyController,
                decoration: const InputDecoration(labelText: 'Allergy or Chronic Condition'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (_allergyController.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance.collection('patients').doc(widget.patientUid).set({
                    'allergies': FieldValue.arrayUnion([_allergyController.text.trim()]),
                  }, SetOptions(merge: true));
                  _allergyController.clear();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('EHR record updated! 🏥'), backgroundColor: Color(0xFF10B981)),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9)),
              child: const Text('Save Note', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
