import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MedicationItem {
  TextEditingController nameController = TextEditingController();

  MedicationItem({String? name}) {
    if (name != null) nameController.text = name;
  }
}

class DoctorWriteRxPage extends StatefulWidget {
  final String? patientUid;
  final String? patientName;
  final String? appointmentId;

  const DoctorWriteRxPage({
    super.key,
    this.patientUid,
    this.patientName,
    this.appointmentId,
  });

  @override
  State<DoctorWriteRxPage> createState() => _DoctorWriteRxPageState();
}

class _DoctorWriteRxPageState extends State<DoctorWriteRxPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _bpController = TextEditingController(text: '120/80');
  final TextEditingController _pulseController = TextEditingController(text: '72');
  final TextEditingController _tempController = TextEditingController(text: '98.6');
  final TextEditingController _instructionsController = TextEditingController();

  DateTime _followUpDate = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;
  final List<MedicationItem> _medications = [];

  @override
  void initState() {
    super.initState();
    if (widget.patientName != null && widget.patientName!.isNotEmpty) {
      _patientNameController.text = widget.patientName!;
    }
    // Add default initial medication row
    _medications.add(MedicationItem(name: 'Paracetamol 500mg'));
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _bpController.dispose();
    _pulseController.dispose();
    _tempController.dispose();
    _instructionsController.dispose();
    for (var med in _medications) {
      med.nameController.dispose();
    }
    super.dispose();
  }

  void _addMedication() {
    setState(() {
      _medications.add(MedicationItem());
    });
  }

  void _removeMedication(int index) {
    if (_medications.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription must include at least one medication.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _medications.removeAt(index);
    });
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor authentication required.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Fetch doctor details
      final docSnap = await FirebaseFirestore.instance.collection('doctors').doc(user.uid).get();
      final docData = docSnap.data() ?? {};
      final doctorName = docData['name'] ?? docData['doctorName'] ?? 'Dr. Specialist';
      final specialization = docData['specialization'] ?? docData['category'] ?? 'Medical Specialist';

      final List<Map<String, String>> medList = _medications.map((m) {
        return {
          'name': m.nameController.text.trim(),
        };
      }).toList();

      final rxRef = await FirebaseFirestore.instance.collection('prescriptions').add({
        'doctorId': user.uid,
        'doctorName': doctorName,
        'specialization': specialization,
        'patientUid': widget.patientUid ?? '',
        'patientName': _patientNameController.text.trim(),
        'appointmentId': widget.appointmentId ?? '',
        'vitals': {
          'bp': _bpController.text.trim(),
          'pulse': _pulseController.text.trim(),
          'temp': _tempController.text.trim(),
        },
        'medications': medList,
        'instructions': _instructionsController.text.trim(),
        'followUpDate': DateFormat('yyyy-MM-dd').format(_followUpDate),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('E-Prescription #${rxRef.id.substring(0, 5).toUpperCase()} issued successfully!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to issue Rx: $e'), backgroundColor: const Color(0xFFEF4444)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: const Color(0xFF0EA5E9),
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.history_edu_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Digital Prescription Pad',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Form Card 1: Patient Details
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.person_rounded, size: 18, color: Color(0xFF3B82F6)),
                                SizedBox(width: 8),
                                Text('PATIENT DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6), letterSpacing: 0.5)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _patientNameController,
                              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter patient name' : null,
                              decoration: InputDecoration(
                                hintText: 'Patient Full Name',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text('PATIENT VITALS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildVitalsInput(_bpController, 'Blood Press.', '120/80', Icons.monitor_heart_rounded)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildVitalsInput(_pulseController, 'Pulse (bpm)', '72', Icons.favorite_rounded)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildVitalsInput(_tempController, 'Temp (°F)', '98.6', Icons.thermostat_rounded)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Form Card 2: Prescriptions
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.medication_rounded, size: 18, color: Color(0xFF3B82F6)),
                                    SizedBox(width: 8),
                                    Text('MEDICATIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6), letterSpacing: 0.5)),
                                  ],
                                ),
                                InkWell(
                                  onTap: _addMedication,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.add_rounded, size: 16, color: Color(0xFF2563EB)),
                                        SizedBox(width: 4),
                                        Text('Add', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _medications.length,
                              itemBuilder: (context, index) {
                                final med = _medications[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: med.nameController,
                                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                          decoration: InputDecoration(
                                            hintText: 'Medicine Name',
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            filled: true,
                                            fillColor: const Color(0xFFF8FAFC),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFEF4444)),
                                        onPressed: () => _removeMedication(index),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Form Card 3: Advice & Follow Up
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF3B82F6)),
                                SizedBox(width: 8),
                                Text('ADVICE & FOLLOW UP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6), letterSpacing: 0.5)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _instructionsController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Special instructions or advice for the patient...',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                            ),
                            const SizedBox(height: 20),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _followUpDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 90)),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _followUpDate = picked;
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, color: Color(0xFF64748B), size: 18),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Follow-up Date', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 2),
                                            Text(
                                              DateFormat('EEE, MMM d, yyyy').format(_followUpDate),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Icon(Icons.edit_calendar_rounded, color: Color(0xFF0EA5E9), size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _savePrescription,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        'Issue E-Prescription',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsInput(TextEditingController controller, String label, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
      ],
    );
  }
}
