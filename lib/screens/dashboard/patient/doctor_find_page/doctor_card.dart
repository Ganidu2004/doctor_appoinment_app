import 'package:appoinment_app/screens/dashboard/appoiment/appoiment_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appoinment_app/screens/dashboard/doctor/account/doctor_profile.dart';

class DoctorCard extends StatelessWidget {
  final String doctorId;
  final String name;
  final String spec;
  final String rate;
  final String exp; 
  final String dist;
  final String? imageUrl;
  final Timestamp? createdAt; 

  const DoctorCard({
    super.key,
    required this.doctorId, 
    required this.name,
    required this.spec,
    required this.rate,
    required this.exp,
    required this.dist,
    this.imageUrl,
    this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorDetailPage(doctorId: doctorId),
          ),
        );
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 15),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      image: (imageUrl != null && imageUrl!.isNotEmpty)
                          ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
                          : null,
                      color: Colors.grey.shade200,
                    ),
                    child: (imageUrl == null || imageUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 40, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Dr. $name", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        const SizedBox(height: 4),
                        Text(spec, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 16),
                            Text(" $rate", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            const Icon(Icons.work_outline, color: Colors.blueGrey, size: 15),
                            const SizedBox(width: 4),
                            Text("$exp Yrs Experience", style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Book Appointment Button
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    final String patientUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    
                    if (patientUid.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectSlotPage(
                            doctorId: doctorId, 
                            patientUid: patientUid,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please login to book an appointment.")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Book Appointment", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}