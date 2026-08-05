import 'package:appoinment_app/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendedDoctorsPage extends StatelessWidget {
  const RecommendedDoctorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.5,
        title: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                child:  const Icon(
                  Icons.local_hospital_rounded, 
                  size: 32, 
                  color: primaryColor
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'DOC TIME',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
        ],
      ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No doctors available."));
          }
          
          final doctors = snapshot.data!.docs;
          
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final data = doctors[index].data() as Map<String, dynamic>;
              
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        image: data['profileImageUrl'] != null 
                            ? DecorationImage(image: NetworkImage(data['profileImageUrl']), fit: BoxFit.cover) 
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Dr. ${data['name'] ?? 'Doctor'}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(data['specialization'] ?? 'General', style: const TextStyle(color: Color(0xFF0284C7), fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0EA5E9)),
                        minimumSize: const Size(double.infinity, 36),
                      ),
                      child: const Text('Book Now', style: TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}