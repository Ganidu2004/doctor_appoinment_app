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
        title: const Text("Find Doctor", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchTerm = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search doctors by name or specialty...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchTerm = '');
                        },
                      )
                    : Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.map, color: Colors.blue),
                      ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Quick Filters", style: TextStyle(fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => setState(() => _selectedFilter = "All"),
                  child: const Text("Clear all", style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  return _filterChip(_filters[index], _selectedFilter == _filters[index]);
                },
              ),
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No doctors found."));
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
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Registered Doctors", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 15),
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
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  const Icon(Icons.local_hospital, size: 40, color: Colors.blue),
                  const SizedBox(height: 10),
                  const Text("Need a specific specialist?", style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text("Browse our directory of over 500+ verified medical professionals.", textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  OutlinedButton(onPressed: () {}, child: const Text("View Directory"))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.blue,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }
}