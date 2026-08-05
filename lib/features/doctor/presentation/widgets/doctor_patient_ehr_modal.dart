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
  final TextEditingController _itemController = TextEditingController();
  String _selectedCategory = 'Allergies';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  String _formatName(String raw) {
    if (raw.trim().isEmpty) return 'Patient Profile';
    return raw.trim().split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doctorUser = FirebaseAuth.instance.currentUser;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.folder_shared_rounded, color: Color(0xFF0EA5E9), size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_formatName(widget.patientName)}\'s EHR Record',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 3 Feature Tabs: Profile, Medical History (EMR), Visit History
          Container(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0EA5E9),
              unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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

          // Real-time Stream of Patient Record from Firestore
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('patients').doc(widget.patientUid).snapshots(),
              builder: (context, snapshot) {
                Map<String, dynamic> pData = Map<String, dynamic>.from(widget.initialPatientData);
                if (snapshot.hasData && snapshot.data!.exists && snapshot.data!.data() != null) {
                  pData = {...pData, ...(snapshot.data!.data() as Map<String, dynamic>)};
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Dynamic Patient Profile & Demographics
                    _buildPatientProfileTab(pData),

                    // Tab 2: Dynamic EMR / Medical History
                    _buildMedicalHistoryTab(pData),

                    // Tab 3: Dynamic Visit History & Clinical Notes Logs
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
  // TAB 1: PATIENT PROFILE & DEMOGRAPHICS (DYNAMIC FROM DATABASE)
  // -------------------------------------------------------------
  Widget _buildPatientProfileTab(Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String name = (data['name'] ?? widget.patientName).toString();
    final String age = (data['age'] ?? 'N/A').toString();
    final String gender = (data['gender'] ?? 'N/A').toString();
    final String bloodGroup = (data['bloodGroup'] ?? data['blood'] ?? 'Not Specified').toString();
    final String phone = (data['phone'] ?? data['phoneNumber'] ?? data['contact'] ?? 'Not Provided').toString();
    final String email = (data['email'] ?? data['emailAddress'] ?? 'Not Provided').toString();
    final String address = (data['address'] ?? data['residentialAddress'] ?? 'Not Provided').toString();
    
    final String emergencyContactName = (data['emergencyContactName'] ?? data['emergencyName'] ?? 'Not Specified').toString();
    final String emergencyContactPhone = (data['emergencyContactPhone'] ?? data['emergencyPhone'] ?? 'Not Specified').toString();
    final String emergencyRelation = (data['emergencyRelation'] ?? data['relation'] ?? 'Guardian / Relative').toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Demographic Hero Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE0F2FE),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'P',
                    style: TextStyle(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatName(name),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              age != 'N/A' ? '$age Yrs • $gender' : gender,
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? const Color(0xFFB91C1C) : const Color(0xFFFCA5A5)),
                            ),
                            child: Text(
                              'Blood: $bloodGroup 🩸',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B)),
                            ),
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

          // Contact Details Section
          Text('Contact Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildInfoTile(Icons.phone_iphone_rounded, 'Phone Number', phone),
                Divider(height: 16, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                _buildInfoTile(Icons.email_outlined, 'Email Address', email),
                Divider(height: 16, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                _buildInfoTile(Icons.location_on_outlined, 'Residential Address', address),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Emergency Contacts Section
          Text('Emergency Contacts 🚨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFECDD3)),
            ),
            child: Column(
              children: [
                _buildInfoTile(
                  Icons.contact_phone_outlined,
                  'Contact Name & Relation',
                  emergencyContactName != 'Not Specified' ? '$emergencyContactName ($emergencyRelation)' : 'Not Specified',
                  titleColor: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF9F1239),
                ),
                Divider(height: 16, color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFECDD3)),
                _buildInfoTile(
                  Icons.phone_in_talk_rounded,
                  'Emergency Phone',
                  emergencyContactPhone,
                  titleColor: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF9F1239),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: MEDICAL HISTORY (EMR / EHR) - DYNAMIC FROM DATABASE
  // -------------------------------------------------------------
  Widget _buildMedicalHistoryTab(Map<String, dynamic> data) {
    final List<String> allergies = (data['allergies'] is List)
        ? (data['allergies'] as List).map((e) => e.toString()).toList()
        : [];

    final List<String> diagnoses = (data['diagnoses'] is List)
        ? (data['diagnoses'] as List).map((e) => e.toString()).toList()
        : [];

    final List<String> surgeries = (data['surgeries'] is List)
        ? (data['surgeries'] as List).map((e) => e.toString()).toList()
        : [];

    final List<String> familyHistory = (data['familyHistory'] is List)
        ? (data['familyHistory'] as List).map((e) => e.toString()).toList()
        : [];

    final List<String> medications = (data['currentMedications'] is List)
        ? (data['currentMedications'] as List).map((e) => e.toString()).toList()
        : [];

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
            emptyMessage: 'No known allergies recorded.',
          ),
          const SizedBox(height: 16),

          // Current Medications
          _buildEmrCard(
            title: 'Active Medications 💊',
            color: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFFA7F3D0),
            items: medications,
            chipColor: const Color(0xFFDCFCE7),
            textColor: const Color(0xFF166534),
            emptyMessage: 'No active medications logged.',
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
            emptyMessage: 'No chronic conditions logged.',
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
            emptyMessage: 'No surgical history logged.',
          ),
          const SizedBox(height: 16),

          // Family Medical History
          _buildEmrCard(
            title: 'Family Medical History 🧬',
            color: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFDE68A),
            items: familyHistory,
            chipColor: const Color(0xFFFEF3C7),
            textColor: const Color(0xFFB45309),
            emptyMessage: 'No family medical history recorded.',
          ),
          const SizedBox(height: 20),

          // Add Allergy / EMR Entry Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddEmrDialog(context),
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0EA5E9)),
              label: const Text('+ Add Clinical Note / Allergy', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9))),
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
  // TAB 3: VISIT HISTORY & CLINICAL NOTES LOGS (DYNAMIC FROM DATABASE)
  // -------------------------------------------------------------
  Widget _buildVisitHistoryTab(String? doctorId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('patientUid', isEqualTo: widget.patientUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
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
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final data = docs[index].data() as Map<String, dynamic>;
            final String date = (data['date'] ?? 'N/A').toString();
            final String time = (data['time'] ?? 'N/A').toString();
            final String status = (data['status'] ?? 'Booked').toString();
            final String hospital = (data['hospitalName'] ?? data['hospital'] ?? 'Consultation Center').toString();
            final String notes = (data['notes'] ?? data['reason'] ?? 'Routine consultation').toString();
            final String diagnosis = (data['diagnosis'] ?? 'Consultation Completed').toString();
            final String cType = (data['consultationType'] ?? 'In-Person Clinic').toString();
            final String tokenStr = (data['queueToken'] ?? (data['tokenNumber'] != null ? '#${data['tokenNumber'].toString().padLeft(2, '0')}' : '')).toString();

            final bool isCompleted = status.toLowerCase().contains('complet');
            final bool isCancelled = status.toLowerCase().contains('cancel');

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                          Text('$date • $time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                          if (tokenStr.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(tokenStr, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))),
                            ),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                              : isCancelled
                                  ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2))
                                  : (isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCompleted
                                ? (isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0))
                                : isCancelled
                                    ? (isDark ? const Color(0xFFB91C1C) : const Color(0xFFFECDD3))
                                    : (isDark ? const Color(0xFFB45309) : const Color(0xFFFDE68A)),
                          ),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
                                : isCancelled
                                    ? (isDark ? const Color(0xFFFCA5A5) : Colors.redAccent)
                                    : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Center: $hospital • $cType', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Impression: $diagnosis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: isDark ? Colors.white : const Color(0xFF334155))),
                        const SizedBox(height: 4),
                        Text('Notes / Reason: $notes', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 18, color: titleColor ?? const Color(0xFF0EA5E9)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: titleColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)))),
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
    required String emptyMessage,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : textColor)),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(emptyMessage, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : chipColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(item, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : textColor)),
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
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Clinical Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'Allergies', child: Text('Allergies & Adverse Reactions')),
                      DropdownMenuItem(value: 'Medications', child: Text('Active Medication')),
                      DropdownMenuItem(value: 'Diagnoses', child: Text('Past Diagnoses / Chronic Condition')),
                      DropdownMenuItem(value: 'Surgeries', child: Text('Surgeries & Procedures')),
                      DropdownMenuItem(value: 'FamilyHistory', child: Text('Family Medical History')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _itemController,
                    decoration: const InputDecoration(labelText: 'Entry details (e.g. Penicillin, Asthma)'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final text = _itemController.text.trim();
                    if (text.isNotEmpty) {
                      String fieldKey = 'allergies';
                      if (_selectedCategory == 'Medications') fieldKey = 'currentMedications';
                      if (_selectedCategory == 'Diagnoses') fieldKey = 'diagnoses';
                      if (_selectedCategory == 'Surgeries') fieldKey = 'surgeries';
                      if (_selectedCategory == 'FamilyHistory') fieldKey = 'familyHistory';

                      await FirebaseFirestore.instance.collection('patients').doc(widget.patientUid).set({
                        fieldKey: FieldValue.arrayUnion([text]),
                      }, SetOptions(merge: true));

                      _itemController.clear();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('EHR record updated! 🏥'), backgroundColor: Color(0xFF10B981)),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9)),
                  child: const Text('Save Entry', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
