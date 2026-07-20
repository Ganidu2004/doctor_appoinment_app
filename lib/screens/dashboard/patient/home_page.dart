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

                                   return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.grey.shade100),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: InkWell(
                                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorDetailPage(doctorId: docDoc.id))),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue.shade50,
                                                        borderRadius: BorderRadius.circular(16),
                                                        image: imageUrl != null && imageUrl.isNotEmpty 
                                                            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) 
                                                            : null,
                                                      ),
                                                      child: imageUrl == null || imageUrl.isEmpty 
                                                          ? const Icon(Icons.person, size: 40, color: Colors.blue) 
                                                          : null,
                                                    ),
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black.withValues(alpha: 0.6),
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                                                            const SizedBox(width: 2),
                                                            Text(
                                                              avgRating > 0 ? avgRating.toStringAsFixed(1) : 'New',
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Dr. ${data['name'] ?? 'Doctor'}', 
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), 
                                                maxLines: 1, 
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                data['specialization'] ?? 'General', 
                                                style: TextStyle(color: Colors.blue[600], fontSize: 11, fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${data['experience'] ?? 0}+ Yrs Exp', 
                                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text('Give your Rating', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
            final now = DateTime.now();

            var docs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              try {
                return DateFormat("MMMM d, yyyy").parse(data['date']).isAfter(now.subtract(const Duration(days: 1)));
              } catch (e) {
                return false;
              }
            }).toList();

            if (docs.isEmpty) return const SizedBox.shrink();

            // Sort appointments to get the soonest one
            docs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              try {
                final aTime = DateFormat("MMMM d, yyyy").parse(aData['date']);
                final bTime = DateFormat("MMMM d, yyyy").parse(bData['date']);
                return aTime.compareTo(bTime);
              } catch (_) {
                return 0;
              }
            });

            final doc = docs.first;
            final data = doc.data() as Map<String, dynamic>;
            final doctorId = data['doctorId'] ?? '';
            final String imageUrl = doctorImages[doctorId] ?? '';
            final status = (data['status'] ?? 'Booked').toString();

            return InkWell(
              onTap: () {
                if (doctorId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DoctorDetailPage(doctorId: doctorId)),
                  );
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.blue[50],
                            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                            child: imageUrl.isEmpty ? const Icon(Icons.person, size: 30, color: Colors.blue) : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dr. ${data['doctorName']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                data['specialization'] ?? 'Specialist',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${data['date']} | ${data['time']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data['hospitalName'] ?? 'Hospital',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
      {
        'icon': Icons.medical_services_rounded, 
        'label': 'Search', 
        'page': const FindDoctorScreen(),
        'bgColor': const Color(0xFFEFF6FF),
        'iconColor': const Color(0xFF3B82F6),
      },
      {
        'icon': Icons.calendar_today_rounded, 
        'label': 'Appointments', 
        'page': const PatientAppointmentsPage(showAppBar: true),
        'bgColor': const Color(0xFFECFDF5),
        'iconColor': const Color(0xFF10B981),
      },
      {
        'icon': Icons.assignment_rounded, 
        'label': 'Profile', 
        'page': const PatientAccount(showAppBar: true),
        'bgColor': const Color(0xFFF5F3FF),
        'iconColor': const Color(0xFF8B5CF6),
      },
      {
        'icon': Icons.forum_rounded, 
        'label': 'Support', 
        'page': const PatientSupportPage(showAppBar: true),
        'bgColor': const Color(0xFFFFF7ED),
        'iconColor': const Color(0xFFF97316),
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) {
        final page = a['page'] as Widget;
        final bgColor = a['bgColor'] as Color;
        final iconColor = a['iconColor'] as Color;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        a['icon'] as IconData, 
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a['label'] as String, 
                      style: const TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
              .collection('reviews')
              .where('patientUid', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, reviewsSnapshot) {
            final Map<String, int> ratedDoctors = {};
            if (reviewsSnapshot.hasData) {
              for (var doc in reviewsSnapshot.data!.docs) {
                final rData = doc.data() as Map<String, dynamic>;
                final docId = rData['doctorId']?.toString();
                final rating = rData['rating'];
                if (docId != null && rating is num) {
                  ratedDoctors[docId] = rating.toInt();
                }
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
                    final hasReviewed = ratedDoctors.containsKey(doctorId);
                    final existingRating = ratedDoctors[doctorId] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue.shade100, width: 1.5),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue.shade50,
                            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                            child: imageUrl.isEmpty ? const Icon(Icons.person, color: Colors.blue) : null,
                          ),
                        ),
                        title: Text(
                          'Dr. $doctorName',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            spec,
                            style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          ),
                        ),
                        trailing: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => DoctorRatingDialog(
                                doctorId: doctorId,
                                doctorName: doctorName,
                                patientUid: user.uid,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: hasReviewed ? Colors.green.shade50 : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: hasReviewed ? Colors.green : Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hasReviewed ? 'Rated $existingRating' : 'Rate',
                                  style: TextStyle(
                                    color: hasReviewed ? Colors.green.shade900 : Colors.amber.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
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

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor 😞';
      case 2:
        return 'Fair 😐';
      case 3:
        return 'Good 🙂';
      case 4:
        return 'Very Good 😊';
      case 5:
        return 'Excellent! 🤩';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          height: 150,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Gradient Block
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.star_rate_rounded, color: Colors.amber, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Rate Dr. ${widget.doctorName}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content Block
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    'How was your experience?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Star Selection Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      final isSelected = starValue <= _rating;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = starValue),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          transform: isSelected 
                              ? Matrix4.diagonal3Values(1.1, 1.1, 1.1) 
                              : Matrix4.identity(),
                          child: Icon(
                            Icons.star_rounded,
                            color: isSelected ? Colors.amber : Colors.grey[300],
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  
                  // Star feedback label
                  const SizedBox(height: 10),
                  Text(
                    _getRatingText(_rating),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Comment TextField
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Share details of your consultation (optional)...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.blue, Colors.blueAccent],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _submitReview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}