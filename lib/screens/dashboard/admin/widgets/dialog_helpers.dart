import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDialogHelpers {
  static Color getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'checked in':
      case 'completed':
        return const Color(0xFFECFDF5);
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'booked':
        return const Color(0xFFEFF6FF);
      case 'cancelled':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  static Color getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'checked in':
      case 'completed':
        return const Color(0xFF059669);
      case 'pending':
        return const Color(0xFFD97706);
      case 'booked':
        return const Color(0xFF2563EB);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF4B5563);
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

    InputDecoration fieldDeco(String hint, IconData icon) {
      return InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(icon, color: Colors.blue[400], size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_rounded, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text("Register Doctor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: nameController, 
                  decoration: fieldDeco("Doctor Name (e.g. Dr. Emily)", Icons.person_outline),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedSpec,
                  decoration: fieldDeco("Specialization", Icons.workspace_premium_outlined),
                  items: specializations.map((spec) => DropdownMenuItem(value: spec, child: Text(spec, style: const TextStyle(fontSize: 14)))).toList(),
                  onChanged: (val) { if (val != null) selectedSpec = val; },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController, 
                  decoration: fieldDeco("Contact Phone", Icons.phone_outlined), 
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: experienceController, 
                  decoration: fieldDeco("Years of Experience", Icons.star_outline), 
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeController, 
                  decoration: fieldDeco("Consultation Fee (LKR)", Icons.payment_outlined), 
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hospitalNameController, 
                  decoration: fieldDeco("Hospital Name", Icons.local_hospital_outlined),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hospitalPhoneController, 
                  decoration: fieldDeco("Hospital Contact Phone", Icons.contact_phone_outlined),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text("Cancel", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.2),
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

    InputDecoration fieldDeco(String hint, IconData icon) {
      return InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(icon, color: Colors.blue[400], size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text("Add New Hospital", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: nameController, 
                  decoration: fieldDeco("Hospital Name", Icons.local_hospital_outlined),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController, 
                  decoration: fieldDeco("Address", Icons.location_on_outlined),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: districtController, 
                  decoration: fieldDeco("District", Icons.map_outlined),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController, 
                  decoration: fieldDeco("Contact Number", Icons.phone_outlined), 
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: chargesController, 
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
              child: Text("Cancel", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.2),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Appointment: #${doc.id.substring(0, min(doc.id.length, 6)).toUpperCase()}", 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              Text("Patient Name: ${data['patientName'] ?? 'N/A'}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text("Doctor: ${data['doctorName'] ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade700)),
              Text("Department: ${data['specialization'] ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade700)),
              Text("Hospital: ${data['hospitalName'] ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade700)),
              Text("Time: ${data['date']} at ${data['time']}", style: TextStyle(color: Colors.grey.shade700)),
              Text("Payment: $paymentMethod (Fee: LKR ${consultationFee.toStringAsFixed(0)} + Charges: LKR ${hospitalCharges.toStringAsFixed(0)})", 
                style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 16),
              const Text("Manage Status:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Pending', 'Checked in', 'Completed', 'Cancelled'].map((newStatus) {
                  final bool active = status.toLowerCase() == newStatus.toLowerCase();
                  return ChoiceChip(
                    label: Text(newStatus),
                    selected: active,
                    selectedColor: getStatusBgColor(newStatus),
                    labelStyle: TextStyle(
                      color: active ? getStatusTextColor(newStatus) : Colors.black87,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal
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
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    side: BorderSide(color: Colors.red.shade100)
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("Delete Appointment Record"),
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
        );
      },
    );
  }
}
