import 'package:appoinment_app/screens/dashboard/doctor/account/doctor_profile.dart';
import 'package:appoinment_app/screens/dashboard/patient/account/patient_account.dart';
import 'package:appoinment_app/screens/dashboard/patient/appointments/patient_appointments_page.dart';
import 'package:appoinment_app/screens/dashboard/patient/doctor_find_page/find_doctor.dart';
import 'package:appoinment_app/screens/dashboard/patient/support/patient_support_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appoinment_app/screens/dashboard/patient/navigator/header.dart';
import 'package:appoinment_app/screens/dashboard/patient/doctor_find_page/recommond_doctor.dart';
import 'package:intl/intl.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  String _patientName = "Patient";
  String _profileImageUrl = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(currentUser.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            _patientName = data['name'] ?? "Patient";
            _profileImageUrl = data['profileImageUrl'] ?? "";
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchUserData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PatientGreetingHeader(name: _patientName, profileImageUrl: _profileImageUrl),
                      const SizedBox(height: 20),
                      const _UpcomingVisitCard(),
                      const SizedBox(height: 24),
                      const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),
                      const _QuickActionsGrid(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recommended Doctors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecommendedDoctorsPage())),
                            child: const Text('See All', style: TextStyle(color: Colors.blue)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
                        builder: (context, doctorsSnapshot) {
                          if (!doctorsSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
                            builder: (context, reviewsSnapshot) {
                              final doctors = doctorsSnapshot.data!.docs;
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

                              // Sort doctors list based on average rating (fallback to 0.0)
                              final sortedDoctors = doctors.toList()
                                ..sort((a, b) {
                                  final ratingA = averageRatings[a.id] ?? 0.0;
                                  final ratingB = averageRatings[b.id] ?? 0.0;
                                  return ratingB.compareTo(ratingA); // Descending
                                });

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 10, mainAxisSpacing: 10),
                                itemCount: sortedDoctors.length >= 2 ? 2 : sortedDoctors.length,
                                itemBuilder: (context, index) {
                                  final docDoc = sortedDoctors[index];
                                  final data = docDoc.data() as Map<String, dynamic>;
                                  final String? imageUrl = data['profileImageUrl'];
                                  final avgRating = averageRatings[docDoc.id] ?? 0.0;

                                  return InkWell(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorDetailPage(doctorId: docDoc.id))),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Expanded(
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                              image: imageUrl != null && imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                                            ),
                                            child: imageUrl == null || imageUrl.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.blue) : null,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Dr. ${data['name'] ?? 'Doctor'}', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text(data['specialization'] ?? 'General', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              avgRating > 0 ? avgRating.toStringAsFixed(1) : 'No reviews',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: avgRating > 0 ? Colors.black87 : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ]),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),
                      const _RecentActivityList(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _UpcomingVisitCard extends StatelessWidget {
  const _UpcomingVisitCard();
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('appointments').where('patientUid', isEqualTo: user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
        final now = DateTime.now();
        var docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          try { return DateFormat("MMMM d, yyyy").parse(data['date']).isAfter(now.subtract(const Duration(days: 1))); } catch (e) { return false; }
        }).toList();
        if (docs.isEmpty) return const SizedBox();
        final data = docs.first.data() as Map<String, dynamic>;
        final String? doctorImageUrl = data['doctorImageUrl'];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF3F8FF), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Row(children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                backgroundImage: (doctorImageUrl != null && doctorImageUrl.isNotEmpty) ? NetworkImage(doctorImageUrl) : null,
                child: (doctorImageUrl == null || doctorImageUrl.isEmpty) ? const Icon(Icons.person, size: 30) : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(data['doctorName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(data['specialization'] ?? 'Doctor', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ]),
              ),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(10)),
                child: Text(data['status'], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12))),
            ]),
            const SizedBox(height: 15),
            Row(children: [const Icon(Icons.access_time, size: 16, color: Colors.grey), const SizedBox(width: 5), Text("${data['date']} | ${data['time']}", style: const TextStyle(color: Colors.grey))]),
          ]),
        );
      },
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();
  @override
  Widget build(BuildContext context) {
    final actions = [
      {'icon': Icons.medical_services, 'label': 'Search', 'page': const FindDoctorScreen()},
      {'icon': Icons.calendar_today_outlined, 'label': 'Appointments', 'page': const PatientAppointmentsPage(showAppBar: true)},
      {'icon': Icons.assignment, 'label': 'Profile', 'page': const PatientAccount(showAppBar: true)},
      {'icon': Icons.chat, 'label': 'Support', 'page': const PatientSupportPage(showAppBar: true)},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) {
        final page = a['page'] as Widget;
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
                child: Icon(a['icon'] as IconData),
              ),
              const SizedBox(height: 5),
              Text(a['label'] as String, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
      builder: (context, doctorsSnapshot) {
        final Map<String, String> doctorImages = {};
        if (doctorsSnapshot.hasData) {
          for (var doc in doctorsSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final img = data['profileImageUrl'] ?? data['imageUrl'] ?? '';
            doctorImages[doc.id] = img.toString();
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('appointments')
              .where('patientUid', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text('No booked doctors yet. Find doctors to schedule appointments.', 
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              );
            }

            // Group by doctorId to get unique list of booked doctors
            final docs = snapshot.data!.docs;
            final Map<String, Map<String, dynamic>> bookedDoctors = {};
            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final doctorId = data['doctorId'];
              if (doctorId != null) {
                bookedDoctors[doctorId] = {
                  'id': doctorId,
                  'name': data['doctorName'] ?? 'Doctor',
                  'specialization': data['specialization'] ?? 'Specialist',
                };
              }
            }

            final doctorList = bookedDoctors.values.toList();

            return Column(
              children: doctorList.map((docInfo) {
                final doctorId = docInfo['id'];
                final doctorName = docInfo['name'];
                final spec = docInfo['specialization'];
                final imageUrl = doctorImages[doctorId] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                      child: imageUrl.isEmpty ? const Icon(Icons.person, color: Colors.blue) : null,
                    ),
                    title: Text(
                      'Dr. $doctorName',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(spec),
                    trailing: TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => DoctorRatingDialog(
                            doctorId: doctorId,
                            doctorName: doctorName,
                            patientUid: user.uid,
                          ),
                        );
                      },
                      icon: const Icon(Icons.star, color: Colors.amber, size: 18),
                      label: const Text('Rate'),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class DoctorRatingDialog extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String patientUid;

  const DoctorRatingDialog({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.patientUid,
  });

  @override
  State<DoctorRatingDialog> createState() => _DoctorRatingDialogState();
}

class _DoctorRatingDialogState extends State<DoctorRatingDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _loading = true;
  String? _reviewDocId;

  @override
  void initState() {
    super.initState();
    _loadExistingReview();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingReview() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('patientUid', isEqualTo: widget.patientUid)
          .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        setState(() {
          _rating = data['rating'] is num ? (data['rating'] as num).toInt() : 5;
          _commentController.text = data['comment']?.toString() ?? '';
          _reviewDocId = snap.docs.first.id;
        });
      }
    } catch (e) {
      debugPrint("Error loading review: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitReview() async {
    setState(() => _loading = true);
    try {
      final data = {
        'doctorId': widget.doctorId,
        'doctorName': widget.doctorName,
        'patientUid': widget.patientUid,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_reviewDocId != null) {
        await FirebaseFirestore.instance.collection('reviews').doc(_reviewDocId).update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('reviews').add(data);
      }

      if (mounted) {
        // Also trigger success notification
        try {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review submitted successfully!')),
          );
        } catch (_) {}
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error saving review: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save review: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Rate Dr. ${widget.doctorName}', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tap stars to rate:'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  icon: Icon(
                    starValue <= _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => _rating = starValue),
                );
              }),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Leave a comment about your experience...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submitReview,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}