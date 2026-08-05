import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDialogHelpers {
  static Color getStatusBgColor(String status, [bool isDark = false]) {
    final lower = status.toLowerCase();
    if (lower.contains('cancel')) {
      return isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);
    }
    switch (lower) {
      case 'checked in':
      case 'completed':
        return isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
      case 'pending':
        return isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
      case 'booked':
      case 'confirmed':
        return isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF);
      default:
        return isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6);
    }
  }

  static Color getStatusTextColor(String status, [bool isDark = false]) {
    final lower = status.toLowerCase();
    if (lower.contains('cancel')) {
      return isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
    }
    switch (lower) {
      case 'checked in':
      case 'completed':
        return isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      case 'pending':
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      case 'booked':
      case 'confirmed':
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
      default:
        return isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B5563);
    }
  }

  static void showAddDoctor(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final experienceController = TextEditingController();
    final feeController = TextEditingController();
    final hospitalNameController = TextEditingController(text: "DocConnect Central Hospital");
    final hospitalPhoneController = TextEditingController(text: "+94 11 234 5678");
    String selectedSpec = "General Practitioner";

    final specializations = [
      "Cardiologist",
      "Pediatrician",
      "Neurologist",
      "Orthopedic Surgeon",
      "General Practitioner",
      "Dermatologist",
      "Psychiatrist"
    ];

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        InputDecoration fieldDeco(String hint, IconData icon) {
          return InputDecoration(
            labelText: hint,
            labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey[500], fontSize: 13),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
            prefixIcon: Icon(icon, color: const Color(0xFF0EA5E9), size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
            ),
          );
        }

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_rounded, color: Color(0xFF0EA5E9), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                "Register Doctor",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: fieldDeco("Doctor Name (e.g. Dr. Emily)", Icons.person_outline),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedSpec,
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: fieldDeco("Specialization", Icons.workspace_premium_outlined),
                  items: specializations
                      .map((spec) => DropdownMenuItem(
                            value: spec,
                            child: Text(
                              spec,
                              style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) selectedSpec = val;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: fieldDeco("Contact Phone", Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: experienceController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: fieldDeco("Years of Experience", Icons.star_outline),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: fieldDeco("Consultation Fee (LKR)", Icons.payment_outlined),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hospitalNameController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: fieldDeco("Hospital Name", Icons.local_hospital_outlined),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hospitalPhoneController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: fieldDeco("Hospital Contact Phone", Icons.contact_phone_outlined),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) return;

                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  final double fee = double.tryParse(feeController.text) ?? 1500.0;
                  final int exp = int.tryParse(experienceController.text) ?? 5;

                  final docRef = FirebaseFirestore.instance.collection('doctors').doc();
                  final String docId = docRef.id;

                  await docRef.set({
                    'uid': docId,
                    'name': nameController.text.trim(),
                    'specialization': selectedSpec,
                    'phone': phoneController.text.trim(),
                    'experience': exp,
                    'personalPhone': phoneController.text.trim(),
                    'profileImageUrl': '',
                    'aboutMe': 'Experienced $selectedSpec dedicated to patient wellness and high-quality care.',
                    'gender': 'Male',
                    'createdAt': FieldValue.serverTimestamp(),
                    'qualifications': ['MBBS', 'MD'],
                    'hospitalPhones': [hospitalPhoneController.text.trim()],
                    'hospitalsList': [
                      {
                        'hospitalName': hospitalNameController.text.trim(),
                        'hospitalPhone': hospitalPhoneController.text.trim(),
                        'hospitalDistrict': 'Colombo',
                        'hospitalAddresses': ['No. 120, Colombo Rd, Colombo 03']
                      }
                    ]
                  });

                  final days = ['Monday', 'Wednesday', 'Friday'];
                  for (var day in days) {
                    final schRef = docRef.collection('schedules').doc();
                    await schRef.set({
                      'id': schRef.id,
                      'day': day,
                      'startTime': '09:00 AM',
                      'endTime': '12:00 PM',
                      'maxPatients': 15,
                      'consultationFee': fee,
                      'hospitalName': hospitalNameController.text.trim(),
                      'hospitalPhone': hospitalPhoneController.text.trim(),
                      'isActive': true
                    });
                  }

                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text("Dr. ${nameController.text.trim()} registered successfully!")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Register", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        );
      },
    );
  }

  static void showAddHospital(BuildContext context) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final districtController = TextEditingController();
    final phoneController = TextEditingController();
    final chargesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        InputDecoration fieldDeco(String hint, IconData icon) {
          return InputDecoration(
            labelText: hint,
            labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey[500], fontSize: 13),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
            prefixIcon: Icon(icon, color: const Color(0xFF0EA5E9), size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
            ),
          );
        }

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF0EA5E9), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                "Add New Hospital",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: fieldDeco("Hospital Name", Icons.local_hospital_outlined),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: fieldDeco("Address", Icons.location_on_outlined),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: districtController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: fieldDeco("District", Icons.map_outlined),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: fieldDeco("Contact Number", Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: chargesController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: fieldDeco("Hospital Charges (LKR)", Icons.payment_outlined),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty || addressController.text.trim().isEmpty) return;

                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  final double charges = double.tryParse(chargesController.text) ?? 500.0;

                  await FirebaseFirestore.instance.collection('hospital').add({
                    'name': nameController.text.trim(),
                    'address': addressController.text.trim(),
                    'district': districtController.text.trim(),
                    'contact': phoneController.text.trim(),
                    'charges': charges,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Hospital added successfully!")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        );
      },
    );
  }

  static void showAppointmentDetails(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = (data['status'] ?? 'Booked').toString();
    final paymentMethod = (data['paymentMethod'] ?? 'Direct Payment').toString();
    final consultationFee = data['consultationFee'] is num ? (data['consultationFee'] as num).toDouble() : 0.0;
    final hospitalCharges = data['hospitalCharges'] is num ? (data['hospitalCharges'] as num).toDouble() : 0.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Appointment: #${doc.id.substring(0, min(doc.id.length, 6)).toUpperCase()}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: isDark ? const Color(0xFF94A3B8) : Colors.black54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text(
                    "Patient Name: ${data['patientName'] ?? 'N/A'}",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Doctor: ${data['doctorName'] ?? 'N/A'}",
                    style: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700, fontSize: 13.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Department: ${data['specialization'] ?? 'N/A'}",
                    style: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700, fontSize: 13.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Hospital: ${data['hospitalName'] ?? 'N/A'}",
                    style: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700, fontSize: 13.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Time: ${data['date']} at ${data['time']}",
                    style: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700, fontSize: 13.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Payment: $paymentMethod (Fee: LKR ${consultationFee.toStringAsFixed(0)} + Charges: LKR ${hospitalCharges.toStringAsFixed(0)})",
                    style: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700, fontSize: 13.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Manage Status:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Pending', 'Checked in', 'Completed', 'Cancelled'].map((newStatus) {
                      final bool active = status.toLowerCase() == newStatus.toLowerCase();
                      final bgColor = getStatusBgColor(newStatus, isDark);
                      final textColor = getStatusTextColor(newStatus, isDark);

                      return ChoiceChip(
                        label: Text(newStatus),
                        selected: active,
                        selectedColor: bgColor,
                        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        side: BorderSide(
                          color: active
                              ? textColor
                              : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                        ),
                        labelStyle: TextStyle(
                          color: active ? textColor : (isDark ? const Color(0xFF94A3B8) : Colors.black87),
                          fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) async {
                          if (selected) {
                            await doc.reference.update({'status': newStatus});

                            // Update linked payment if completed
                            final String? paymentId = data['paymentId']?.toString();
                            if (paymentId != null && paymentId.isNotEmpty) {
                              await FirebaseFirestore.instance.collection('payments').doc(paymentId).update({
                                'paymentStatus': newStatus == 'Completed' ? 'Completed' : 'Pending'
                              });
                            }

                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF450A0A) : Colors.red.shade50,
                        foregroundColor: isDark ? const Color(0xFFFCA5A5) : Colors.red,
                        elevation: 0,
                        side: BorderSide(color: isDark ? const Color(0xFF991B1B) : Colors.red.shade100),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text("Delete Appointment Record", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        await doc.reference.delete();
                        final String? paymentId = data['paymentId']?.toString();
                        if (paymentId != null && paymentId.isNotEmpty) {
                          await FirebaseFirestore.instance.collection('payments').doc(paymentId).delete();
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
