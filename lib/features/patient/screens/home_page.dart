import 'package:appoinment_app/features/doctor/screens/doctor_profile.dart';
import 'package:appoinment_app/features/patient/screens/patient_account.dart';
import 'package:appoinment_app/features/patient/screens/patient_appointments_page.dart';
import 'package:appoinment_app/features/patient/screens/find_doctor.dart';
import 'package:appoinment_app/features/patient/screens/patient_support_page.dart';
import 'package:flutter/material.dart';
import 'package:appoinment_app/features/patient/screens/patient_prescriptions_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appoinment_app/features/patient/navigator/header.dart';
import 'package:appoinment_app/features/patient/screens/recommend_doctor.dart';
import 'package:appoinment_app/services/schedule_cancellation_service.dart';
import 'package:appoinment_app/features/appointments/screens/hospital_booking_pass_page.dart';
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
                      const SizedBox(height: 14),
                      // Daraz-Style Search Quick Jump
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FindDoctorScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, color: Color(0xFF0EA5E9), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Search doctors, specialties, hospitals...',
                                  style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.tune_rounded, color: Color(0xFF0EA5E9), size: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _PromoBannerSlider(),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Medical Specialties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.3)),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FindDoctorScreen())),
                            child: const Text('All Specialties >', style: TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const _MedicalSpecialtiesGrid(),
                      const SizedBox(height: 16),
                      const _CancellationInvoicesSection(),
                      const SizedBox(height: 16),
                      const _UpcomingVisitCard(),
                      const SizedBox(height: 24),
                      const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.3)),
                      const SizedBox(height: 14),
                      const _QuickActionsGrid(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recommended Doctors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.3)),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecommendedDoctorsPage())),
                            child: const Text('See All', style: TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold, fontSize: 13)),
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
                                      border: Border.all(color: Colors.grey.shade200),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
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
                                                          color: Colors.black.withValues(alpha: 0.7),
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
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)), 
                                                maxLines: 1, 
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                data['specialization'] ?? 'General', 
                                                style: const TextStyle(color: Color(0xFF0284C7), fontSize: 11.5, fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${data['experience'] ?? 0}+ Yrs Exp', 
                                                style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w500),
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
                      const _MyPrescriptionsSection(),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Give your Rating', 
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.3),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Rate & share feedback on your doctor visits',
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HospitalBookingPassPage(
                      appointmentId: doc.id,
                      appointmentData: data,
                    ),
                  ),
                );
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
            final Map<String, Map<String, dynamic>> ratedDocsInfo = {};
            if (reviewsSnapshot.hasData) {
              for (var doc in reviewsSnapshot.data!.docs) {
                final rData = doc.data() as Map<String, dynamic>;
                final docId = rData['doctorId']?.toString();
                if (docId != null) {
                  ratedDocsInfo[docId] = {
                    'rating': (rData['rating'] is num) ? (rData['rating'] as num).toInt() : 5,
                    'comment': rData['comment']?.toString() ?? '',
                  };
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
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEF3C7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_rate_rounded, color: Color(0xFFD97706), size: 32),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Consultations to Rate Yet',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Book your doctor appointments to share your ratings & feedback!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                        ),
                      ],
                    ),
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
                    final hasReviewed = ratedDocsInfo.containsKey(doctorId);
                    final existingRating = ratedDocsInfo[doctorId]?['rating'] ?? 0;
                    final existingComment = ratedDocsInfo[doctorId]?['comment'] ?? '';

                    return _CreativeRatingCard(
                      key: ValueKey('$doctorId-$hasReviewed-$existingRating'),
                      doctorId: doctorId,
                      doctorName: doctorName,
                      specialization: spec,
                      imageUrl: imageUrl,
                      patientUid: user.uid,
                      hasReviewed: hasReviewed,
                      existingRating: existingRating,
                      existingComment: existingComment,
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

class _CreativeRatingCard extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String specialization;
  final String imageUrl;
  final String patientUid;
  final bool hasReviewed;
  final int existingRating;
  final String existingComment;

  const _CreativeRatingCard({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
    required this.imageUrl,
    required this.patientUid,
    required this.hasReviewed,
    required this.existingRating,
    required this.existingComment,
  });

  @override
  State<_CreativeRatingCard> createState() => _CreativeRatingCardState();
}

class _CreativeRatingCardState extends State<_CreativeRatingCard> {
  late int _selectedRating;
  final List<String> _selectedTags = [];
  bool _isSaving = false;
  bool _isEditing = false;
  final TextEditingController _commentCtrl = TextEditingController();

  final List<String> _availableTags = [
    '⚡ Fast Care',
    '🩺 Detailed Exam',
    '💬 Great Advice',
    '😊 Friendly',
    '⏰ On Time',
  ];

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.hasReviewed && widget.existingRating > 0 ? widget.existingRating : 5;
    _commentCtrl.text = widget.existingComment;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String _getSentimentText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor 😡';
      case 2:
        return 'Fair 😐';
      case 3:
        return 'Good 🙂';
      case 4:
        return 'Very Good 😊';
      case 5:
        return 'Exceptional! 🌟';
      default:
        return '';
    }
  }

  Future<void> _submitQuickRating() async {
    setState(() => _isSaving = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('patientUid', isEqualTo: widget.patientUid)
          .get();

      String commentText = _commentCtrl.text.trim();
      if (_selectedTags.isNotEmpty) {
        final tagsStr = 'Tags: ${_selectedTags.join(', ')}';
        commentText = commentText.isEmpty ? tagsStr : '$commentText ($tagsStr)';
      }

      final data = {
        'doctorId': widget.doctorId,
        'doctorName': widget.doctorName,
        'patientUid': widget.patientUid,
        'rating': _selectedRating,
        'comment': commentText,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (snap.docs.isNotEmpty) {
        await FirebaseFirestore.instance.collection('reviews').doc(snap.docs.first.id).update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('reviews').add(data);
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Thank you for rating Dr. ${widget.doctorName}!')),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save rating: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showRatedState = widget.hasReviewed && !_isEditing;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: showRatedState ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
          width: showRatedState ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: showRatedState
                ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: showRatedState
                          ? [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]
                          : [const Color(0xFF0EA5E9), const Color(0xFF2563EB)],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    backgroundImage: widget.imageUrl.isNotEmpty ? NetworkImage(widget.imageUrl) : null,
                    child: widget.imageUrl.isEmpty ? const Icon(Icons.person, color: Color(0xFF0EA5E9)) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${widget.doctorName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.specialization,
                              style: const TextStyle(
                                color: Color(0xFF0284C7),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 2),
                          const Text(
                            'Completed',
                            style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (showRatedState)
                  GestureDetector(
                    onTap: () => setState(() => _isEditing = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 12, color: Color(0xFFD97706)),
                          SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            if (showRatedState) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (idx) {
                            return Icon(
                              Icons.star_rounded,
                              color: idx < widget.existingRating ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                              size: 18,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.existingRating}.0',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E), fontSize: 13),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getSentimentText(widget.existingRating),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                          ),
                        ),
                      ],
                    ),
                    if (widget.existingComment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '"${widget.existingComment}"',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF451A03),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),

              // Interactive Star Rating Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Rating:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      key: ValueKey(_selectedRating),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getSentimentText(_selectedRating),
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dynamic 5-Star Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final starVal = index + 1;
                  final isSelected = starVal <= _selectedRating;
                  return InkWell(
                    onTap: () => setState(() => _selectedRating = starVal),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: AnimatedScale(
                        scale: isSelected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          Icons.star_rounded,
                          color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                          size: 32,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),

              // Quick Tag Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _availableTags.map((tag) {
                    final isTagSelected = _selectedTags.contains(tag);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: FilterChip(
                        selected: isTagSelected,
                        label: Text(tag),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isTagSelected ? FontWeight.bold : FontWeight.w500,
                          color: isTagSelected ? const Color(0xFF0284C7) : const Color(0xFF475569),
                        ),
                        backgroundColor: const Color(0xFFF8FAFC),
                        selectedColor: const Color(0xFFE0F2FE),
                        checkmarkColor: const Color(0xFF0284C7),
                        side: BorderSide(
                          color: isTagSelected ? const Color(0xFF38BDF8) : const Color(0xFFE2E8F0),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => DoctorRatingDialog(
                            doctorId: widget.doctorId,
                            doctorName: widget.doctorName,
                            patientUid: widget.patientUid,
                          ),
                        );
                      },
                      icon: const Icon(Icons.comment_outlined, size: 14, color: Color(0xFF64748B)),
                      label: const Text('Write Review', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submitQuickRating,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: Size.zero,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded, size: 16, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Submit Rating',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
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
  Set<String> _selectedTags = {};
  bool _wouldRecommend = true;

  final List<String> _availableTags = [
    '👨‍⚕️ Great Advice',
    '⏱️ Minimal Wait',
    '🩺 Thorough Care',
    '🤝 Friendly Staff',
    '✨ Clean Clinic',
    '💊 Clear Plan',
  ];

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

      if (!mounted) return;

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        setState(() {
          _rating = data['rating'] is num ? (data['rating'] as num).toInt() : 5;
          _commentController.text = data['comment']?.toString() ?? '';
          _reviewDocId = snap.docs.first.id;
          if (data['tags'] is List) {
            _selectedTags = Set<String>.from((data['tags'] as List).map((e) => e.toString()));
          }
          if (data['wouldRecommend'] is bool) {
            _wouldRecommend = data['wouldRecommend'] as bool;
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading review: $e");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submitReview() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = {
        'doctorId': widget.doctorId,
        'doctorName': widget.doctorName,
        'patientUid': widget.patientUid,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'tags': _selectedTags.toList(),
        'wouldRecommend': _wouldRecommend,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_reviewDocId != null) {
        await FirebaseFirestore.instance.collection('reviews').doc(_reviewDocId).update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('reviews').add(data);
      }

      if (mounted) {
        try {
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
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildSentimentBadge() {
    switch (_rating) {
      case 5:
        return _badgePill('🌟 Exceptional Consultation!', const Color(0xFFECFDF5), const Color(0xFF047857), const Color(0xFFA7F3D0));
      case 4:
        return _badgePill('😊 Very Satisfied!', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8), const Color(0xFFBFDBFE));
      case 3:
        return _badgePill('🙂 Good Experience', const Color(0xFFF0F9FF), const Color(0xFF0369A1), const Color(0xFFBAE6FD));
      case 2:
        return _badgePill('😐 Could Be Better', const Color(0xFFFEF3C7), const Color(0xFFB45309), const Color(0xFFFDE68A));
      case 1:
        return _badgePill('😡 Disappointed', const Color(0xFFFEE2E2), const Color(0xFFB91C1C), const Color(0xFFFCA5A5));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _badgePill(String label, Color bg, Color text, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
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
      elevation: 12,
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Creative Gradient Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rate_rounded, color: Colors.amber, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rate Your Consultation',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dr. ${widget.doctorName}',
                            style: const TextStyle(
                              color: Color(0xFFE0F2FE),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                    ),
                  ],
                ),
              ),

              // Form Content
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sentiment & Rating Display
                    Center(
                      child: Column(
                        children: [
                          _buildSentimentBadge(),
                          const SizedBox(height: 14),

                          // Interactive Stars
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final starValue = index + 1;
                              final isSelected = starValue <= _rating;
                              return GestureDetector(
                                onTap: () => setState(() => _rating = starValue),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  child: Icon(
                                    Icons.star_rounded,
                                    color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                                    size: 42,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Feedback Tag Chips
                    const Text(
                      'What stood out during your visit?',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return ChoiceChip(
                          label: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0EA5E9),
                          backgroundColor: const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          showCheckmark: false,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Would Recommend Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recommend this doctor?',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _wouldRecommend = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _wouldRecommend ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _wouldRecommend ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  '👍 Yes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _wouldRecommend ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _wouldRecommend = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: !_wouldRecommend ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: !_wouldRecommend ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  '👎 No',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: !_wouldRecommend ? const Color(0xFFB91C1C) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Review Comment TextField
                    TextField(
                      controller: _commentController,
                      maxLines: 3,
                      maxLength: 300,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Write your detailed review & advice for future patients...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(14),
                        counterStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _submitReview,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                              label: const Text(
                                'Submit Review',
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
      ),
    );
  }
}

class _CancellationInvoicesSection extends StatelessWidget {
  const _CancellationInvoicesSection();

  void _showRescheduleDatePicker(BuildContext context, Map<String, dynamic> invData) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );

      if (pickedTime != null && context.mounted) {
        final formattedDate = DateFormat("MMMM d, yyyy").format(pickedDate);
        final formattedTime = pickedTime.format(context);

        final success = await ScheduleCancellationService().resolveInvoiceByReschedule(
          invoiceId: invData['id'] ?? '',
          appointmentId: invData['appointmentId'] ?? '',
          newDate: formattedDate,
          newTime: formattedTime,
        );

        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appointment successfully rescheduled to $formattedDate at $formattedTime!'),
              backgroundColor: const Color(0xFF0EA5E9),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showInvoiceDetailsModal(BuildContext context, Map<String, dynamic> data) {
    final invNum = data['invoiceNumber'] ?? 'INV-CANCELLED';
    final actionType = data['actionType'] ?? 'Pending Patient Choice';
    final isPendingChoice = actionType == 'Pending Patient Choice';
    final remarks = data['remarks'] ?? 'Doctor schedule set to Off/Cancelled.';
    final total = (data['totalAmount'] is num ? (data['totalAmount'] as num).toDouble() : 0.0);
    final fee = (data['consultationFee'] is num ? (data['consultationFee'] as num).toDouble() : 0.0);
    final charges = (data['hospitalCharges'] is num ? (data['hospitalCharges'] as num).toDouble() : 0.0);
    final method = data['paymentMethod'] ?? 'Online';
    final dateStr = data['originalDate'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Colors.redAccent, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cancellation Invoice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          Text('No: $invNum', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPendingChoice
                            ? Colors.orange.withValues(alpha: 0.15)
                            : (actionType == 'Refund' ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPendingChoice
                            ? 'Action Required'
                            : (actionType == 'Refund' ? 'Refund Issued' : 'Rescheduled'),
                        style: TextStyle(
                          color: isPendingChoice
                              ? Colors.orange.shade900
                              : (actionType == 'Refund' ? Colors.green.shade800 : Colors.blue.shade800),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Original Date:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dateStr.isNotEmpty ? dateStr : 'N/A',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment Method:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$method',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Financial Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Consultation Fee', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text('LKR ${fee.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Hospital Service Charges', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text('LKR ${charges.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Invoice Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                    Text('LKR ${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0EA5E9))),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded, color: Colors.green, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Payment Refund Notification:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                            const SizedBox(height: 2),
                            Text(
                              actionType == 'Refund'
                                  ? 'Full refund of LKR ${total.toStringAsFixed(0)} will be credited back to your payment account.'
                                  : 'Your full payment of LKR ${total.toStringAsFixed(0)} will be refunded upon claiming below, or you may choose to reschedule.',
                              style: TextStyle(fontSize: 12, color: Colors.green.shade900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cancellation Reason / Note:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown)),
                      const SizedBox(height: 4),
                      Text(remarks, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ⚡ Interactive Patient Resolution Buttons (if Pending Patient Choice)
                if (isPendingChoice) ...[
                  const Text('Select Resolution Option:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            final success = await ScheduleCancellationService().resolveInvoiceByRefund(
                              invoiceId: data['id'] ?? '',
                              appointmentId: data['appointmentId'] ?? '',
                            );
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Refund claimed successfully! Amount will be returned.'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.account_balance_wallet_rounded, size: 16),
                          label: const Text('Claim Refund', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _showRescheduleDatePicker(context, data);
                          },
                          icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                          label: const Text('Reschedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close Invoice', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('invoices')
          .where('patientId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

        final invoices = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final dateStr = (data['originalDate'] ?? '').toString();
          if (dateStr.isEmpty) return true;
          try {
            final parsedDate = DateFormat("MMMM d, yyyy").parse(dateStr);
            return !parsedDate.isBefore(todayStart);
          } catch (_) {
            try {
              final parsedDate = DateTime.parse(dateStr);
              return !parsedDate.isBefore(todayStart);
            } catch (_) {
              return true;
            }
          }
        }).toList()
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = (aData['issuedAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = (bData['issuedAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });

        if (invoices.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Cancellation Invoices',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${invoices.length} Issued',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invoices.length > 2 ? 2 : invoices.length,
              itemBuilder: (context, index) {
                final invDoc = invoices[index];
                final data = invDoc.data() as Map<String, dynamic>;
                final invNum = data['invoiceNumber'] ?? 'INV-CANCELLED';
                final actionType = data['actionType'] ?? 'Refund';
                final total = (data['totalAmount'] is num ? (data['totalAmount'] as num).toDouble() : 0.0);
                final remarks = data['remarks'] ?? 'Doctor schedule set to Off/Cancelled.';
                final dateStr = data['originalDate'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: actionType == 'Refund'
                          ? [const Color(0xFFFEF2F2), const Color(0xFFFFF1F2)]
                          : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: actionType == 'Refund' ? Colors.red.shade200 : Colors.amber.shade300,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                actionType == 'Refund' ? Icons.cancel_outlined : Icons.event_repeat_rounded,
                                color: actionType == 'Refund' ? Colors.redAccent : Colors.orange.shade800,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                invNum,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: actionType == 'Refund' ? Colors.green.shade700 : Colors.orange.shade800,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              actionType == 'Refund' ? 'Refund Issued' : 'Reschedule Credit',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Appointment on $dateStr was cancelled.',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remarks,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_rounded, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                actionType == 'Refund'
                                    ? 'Full payment of LKR ${total.toStringAsFixed(0)} will be refunded.'
                                    : 'Your payment of LKR ${total.toStringAsFixed(0)} will be refunded upon claiming below (or reschedule for free).',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount: LKR ${total.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0EA5E9)),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _showInvoiceDetailsModal(context, data),
                            icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0EA5E9)),
                            label: const Text('View Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0EA5E9))),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _PromoBannerSlider extends StatefulWidget {
  const _PromoBannerSlider();

  @override
  State<_PromoBannerSlider> createState() => _PromoBannerSliderState();
}

class _PromoBannerSliderState extends State<_PromoBannerSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _banners = [
    {
      'title': '24/7 Specialist Consultations',
      'subtitle': 'Book top doctors & get instant appointment confirmation.',
      'tag': 'HOT OFFER',
      'colors': [const Color(0xFF0EA5E9), const Color(0xFF500CA4)],
      'icon': Icons.medical_services_rounded,
    },
    {
      'title': '15% Off First Booking',
      'subtitle': 'Use promo code DOCTIME15 at checkout today.',
      'tag': 'DISCOUNT',
      'colors': [const Color(0xFF10B981), const Color(0xFF059669)],
      'icon': Icons.local_offer_rounded,
    },
    {
      'title': 'Top Hospital Network',
      'subtitle': 'National Hospital, Asiri & Lanka Hospitals verified doctors.',
      'tag': 'VERIFIED',
      'colors': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      'icon': Icons.apartment_rounded,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: banner['colors'] as List<Color>,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (banner['colors'] as List<Color>).first.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              banner['tag'] as String,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            banner['title'] as String,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            banner['subtitle'] as String,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(banner['icon'] as IconData, color: Colors.white, size: 32),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == index ? const Color(0xFF0EA5E9) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MedicalSpecialtiesGrid extends StatelessWidget {
  const _MedicalSpecialtiesGrid();

  static const List<Map<String, dynamic>> _specialties = [
    {'name': 'General', 'filter': 'General Practitioner', 'icon': Icons.medical_services_rounded, 'color': Color(0xFF0EA5E9)},
    {'name': 'Cardiology', 'filter': 'Cardiologist', 'icon': Icons.favorite_rounded, 'color': Color(0xFFEF4444)},
    {'name': 'Neurology', 'filter': 'Neurologist', 'icon': Icons.psychology_rounded, 'color': Color(0xFF8B5CF6)},
    {'name': 'Orthopedics', 'filter': 'Orthopedic Surgeon', 'icon': Icons.accessibility_new_rounded, 'color': Color(0xFFF59E0B)},
    {'name': 'Pediatrics', 'filter': 'Pediatrician', 'icon': Icons.child_care_rounded, 'color': Color(0xFF10B981)},
    {'name': 'Dental', 'filter': 'Dentist', 'icon': Icons.clean_hands_rounded, 'color': Color(0xFF06B6D4)},
    {'name': 'Eye Care', 'filter': 'Ophthalmologist', 'icon': Icons.visibility_rounded, 'color': Color(0xFF3B82F6)},
    {'name': 'Psychiatry', 'filter': 'Psychiatrist', 'icon': Icons.self_improvement_rounded, 'color': Color(0xFFEC4899)},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.82,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
      ),
      itemCount: _specialties.length,
      itemBuilder: (context, index) {
        final item = _specialties[index];
        final color = item['color'] as Color;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FindDoctorScreen(initialSpecialty: item['filter'] as String),
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.08)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Icon(item['icon'] as IconData, color: color, size: 26),
              ),
              const SizedBox(height: 6),
              Text(
                item['name'] as String,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MyPrescriptionsSection extends StatelessWidget {
  const _MyPrescriptionsSection();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('prescriptions')
          .where('patientUid', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PatientPrescriptionsPage()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.history_edu_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My E-Prescriptions (Rx)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        docs.isNotEmpty
                            ? '${docs.length} Digital Rx Record${docs.length == 1 ? '' : 's'} Issued'
                            : 'Access all digital prescriptions issued by your doctors',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0284C7)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}