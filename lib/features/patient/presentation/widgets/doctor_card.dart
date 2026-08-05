import 'package:appoinment_app/features/appointments/presentation/screens/appointment_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appoinment_app/features/doctor/presentation/screens/doctor_profile.dart';

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
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          image: (imageUrl != null && imageUrl!.isNotEmpty)
                              ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
                              : null,
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                        ),
                        child: (imageUrl == null || imageUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 40, color: Color(0xFF0EA5E9))
                            : null,
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).cardColor, width: 2.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Dr. $name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.white)),
                        const SizedBox(height: 4),
                        Text(spec, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                  const SizedBox(width: 2),
                                  Text(rate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.work_outline_rounded, color: Color(0xFF38BDF8), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              "$exp Yrs Exp", 
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, 
                                fontSize: 12, 
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Book Appointment Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: const Text('Book Appointment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}