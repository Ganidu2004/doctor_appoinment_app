import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MedicationItem {
  TextEditingController nameController = TextEditingController();
  TextEditingController dosageController = TextEditingController(text: '1 - 0 - 1');
  TextEditingController durationController = TextEditingController(text: '5 Days');
  String instruction = 'After Meals';

  MedicationItem({String? name}) {
    if (name != null) nameController.text = name;
  }
}

class DoctorWriteRxModal extends StatefulWidget {
  final String? patientUid;
  final String? patientName;
  final String? appointmentId;

  const DoctorWriteRxModal({
    super.key,
    this.patientUid,
    this.patientName,
    this.appointmentId,
  });

  @override
  State<DoctorWriteRxModal> createState() => _DoctorWriteRxModalState();
}

class _DoctorWriteRxModalState extends State<DoctorWriteRxModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _chiefComplaintController = TextEditingController();
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
    _diagnosisController.dispose();
    _chiefComplaintController.dispose();
    _bpController.dispose();
    _pulseController.dispose();
    _tempController.dispose();
    _instructionsController.dispose();
    for (var med in _medications) {
      med.nameController.dispose();
      med.dosageController.dispose();
      med.durationController.dispose();
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
          'dosage': m.dosageController.text.trim(),
          'duration': m.durationController.text.trim(),
          'instruction': m.instruction,
        };
      }).toList();

      final rxRef = await FirebaseFirestore.instance.collection('prescriptions').add({
        'doctorId': user.uid,
        'doctorName': doctorName,
        'specialization': specialization,
        'patientUid': widget.patientUid ?? '',
        'patientName': _patientNameController.text.trim(),
        'appointmentId': widget.appointmentId ?? '',
        'chiefComplaint': _chiefComplaintController.text.trim(),
        'diagnosis': _diagnosisController.text.trim(),
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
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history_edu_rounded, color: Color(0xFF0EA5E9), size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Issue E-Prescription (Rx)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),

                  // Patient Name Field
                  const Text('PATIENT NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _patientNameController,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter patient name' : null,
                    decoration: InputDecoration(
                      hintText: 'e.g. Ganidu Chalinda',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF0EA5E9), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Clinical Vitals Bar
                  const Text('PATIENT VITALS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _buildVitalsInput(_bpController, 'BP', '120/80'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildVitalsInput(_pulseController, 'Pulse (bpm)', '72'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildVitalsInput(_tempController, 'Temp (°F)', '98.6'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Chief Complaint & Diagnosis
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CHIEF COMPLAINT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _chiefComplaintController,
                              decoration: InputDecoration(
                                hintText: 'e.g. Chest tightness',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DIAGNOSIS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _diagnosisController,
                              validator: (val) => val == null || val.trim().isEmpty ? 'Enter diagnosis' : null,
                              decoration: InputDecoration(
                                hintText: 'e.g. Acute Bronchitis',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Medication Header & Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PRESCRIBED MEDICATIONS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9), letterSpacing: 0.5),
                      ),
                      TextButton.icon(
                        onPressed: _addMedication,
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF0284C7)),
                        label: const Text('+ Add Medicine', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Dynamic Medication List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _medications.length,
                    itemBuilder: (context, index) {
                      final med = _medications[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: med.nameController,
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter medicine' : null,
                                    decoration: InputDecoration(
                                      hintText: 'Medicine Name & Strength',
                                      isDense: true,
                                      contentPadding: const EdgeInsets.all(10),
                                      fillColor: Colors.white,
                                      filled: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: med.dosageController,
                                    decoration: InputDecoration(
                                      hintText: '1 - 0 - 1',
                                      isDense: true,
                                      contentPadding: const EdgeInsets.all(10),
                                      fillColor: Colors.white,
                                      filled: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                  onPressed: () => _removeMedication(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: med.durationController,
                                    decoration: InputDecoration(
                                      hintText: 'Duration (e.g. 5 Days)',
                                      isDense: true,
                                      contentPadding: const EdgeInsets.all(10),
                                      fillColor: Colors.white,
                                      filled: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: med.instruction,
                                        isExpanded: true,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                                        items: ['After Meals', 'Before Meals', 'With Food', 'At Bedtime']
                                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              med.instruction = val;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Additional Instructions
                  const Text('SPECIAL INSTRUCTIONS & ADVICE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _instructionsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Rest well, drink plenty of warm fluids.',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Follow Up Date Picker Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_repeat_rounded, color: Color(0xFF0284C7), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Follow-up Date: ${DateFormat('EEE, MMM d, yyyy').format(_followUpDate)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () async {
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
                        child: const Text('Change Date', style: TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Submit Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _savePrescription,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        label: Text(
                          _isSaving ? 'Issuing E-Prescription...' : 'Issue E-Prescription 📝',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVitalsInput(TextEditingController controller, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
      ],
    );
  }
}
