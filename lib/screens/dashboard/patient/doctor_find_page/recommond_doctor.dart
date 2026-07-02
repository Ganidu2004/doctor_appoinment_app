import 'package:appoinment_app/const.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendedDoctorsPage extends StatelessWidget {
  const RecommendedDoctorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                child:  const Icon(
                  Icons.local_hospital_rounded, 
                  size: 64, 
                  color: primaryColor
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'DOC TIME',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        image: data['profileImageUrl'] != null 
                            ? DecorationImage(image: NetworkImage(data['profileImageUrl']), fit: BoxFit.cover) 
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Dr. ${data['name'] ?? 'Doctor'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1),
                    Text(data['specialization'] ?? 'General', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD6E4FF)),
                        minimumSize: const Size(double.infinity, 36),
                      ),
                      child: const Text('Book Now', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
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