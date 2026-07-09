import 'package:appoinment_app/screens/dashboard/patient/doctor_find_page/doctor_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FindDoctorScreen extends StatefulWidget {
  const FindDoctorScreen({super.key});

  @override
  State<FindDoctorScreen> createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends State<FindDoctorScreen> {
  String _selectedFilter = "All";

  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  final List<String> _filters = [
    "All",
    "Cardiologist",
    "Pediatrician",
    "Dermatologist",
    "Neurologist",
    "General Practitioner",
    "Psychiatrist",
    "Orthopedic Surgeon",
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }



  Widget _filterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Colors.blue, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade200,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.01),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('doctors');
    if (_selectedFilter != "All") {
      query = query.where('specialization', isEqualTo: _selectedFilter);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Find Doctor", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Styled Search Box
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchTerm = val.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: "Search doctors by name or specialty...",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.blue),
                  suffixIcon: _searchTerm.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchTerm = '');
                          },
                        )
                      : Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50, 
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.map_rounded, color: Colors.blue, size: 18),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16), 
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Quick Filters", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedFilter = "All"),
                  child: const Text(
                    "Clear all", 
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  return _filterChip(_filters[index], _selectedFilter == _filters[index]);
                },
              ),
            ),
            const SizedBox(height: 24),
            StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Text("No doctors found.", style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
                  builder: (context, reviewsSnapshot) {
                    final docs = snapshot.data!.docs;
                    final reviews = reviewsSnapshot.data?.docs ?? [];

                    // Calculate average rating for each doctorId
                    final Map<String, List<int>> doctorRatings = {};
                    for (var doc in reviews) {
                      final data = doc.data() as Map<String, dynamic>;
                      final docId = data['doctorId']?.toString();
                      final rating = data['rating'];
                      if (docId != null && rating is num) {
                        doctorRatings.putIfAbsent(docId, () => []).add(rating.toInt());
                      }
                    }

                    final Map<String, double> averageRatings = {};
                    for (var entry in doctorRatings.entries) {
                      final sum = entry.value.reduce((a, b) => a + b);
                      averageRatings[entry.key] = sum / entry.value.length;
                    }

                    final filteredDocs = docs.where((d) {
                      final doc = d.data() as Map<String, dynamic>;
                      final name = (doc['name'] ?? '').toString().toLowerCase();
                      final spec = (doc['specialization'] ?? '').toString().toLowerCase();
                      if (_searchTerm.isEmpty) return true;
                      return name.contains(_searchTerm) || spec.contains(_searchTerm);
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Registered Doctors", 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            final docSnapshot = filteredDocs[index];
                            final doc = docSnapshot.data() as Map<String, dynamic>;
                            final avgRating = averageRatings[docSnapshot.id] ?? 0.0;

                            return DoctorCard(
                              doctorId: docSnapshot.id,
                              name: doc['name'] ?? 'Doctor Name',
                              spec: doc['specialization'] ?? 'Specialty',
                              rate: avgRating > 0 ? avgRating.toStringAsFixed(1) : 'No reviews',
                              exp: doc['experience']?.toString() ?? '0',
                              dist: doc['dist'] ?? 'Location',
                              imageUrl: doc['profileImageUrl'],
                              createdAt: doc['createdAt'] as Timestamp?,
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            // Premium Redesigned Directory Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[900]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_hospital_rounded, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Need a specific specialist?", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Browse our directory of over 500+ verified medical professionals.", 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {}, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue[800],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("View Directory", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}