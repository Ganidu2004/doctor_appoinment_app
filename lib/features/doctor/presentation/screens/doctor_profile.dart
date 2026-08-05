import 'package:appoinment_app/features/appointments/presentation/screens/appointment_page.dart';
import 'package:appoinment_app/features/patient/presentation/screens/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:appoinment_app/core/utils/text_sanitizer.dart';

class DoctorDetailPage extends StatefulWidget {
  final String doctorId;
  const DoctorDetailPage({super.key, required this.doctorId});

  @override
  State<DoctorDetailPage> createState() => _DoctorDetailPageState();
}

class _DoctorDetailPageState extends State<DoctorDetailPage> {
  String hName = "Selecting...";
  String hAddress = "Please select a date";

  late Future<DocumentSnapshot> _doctorFuture;
  late Future<QuerySnapshot> _scheduleFuture;

  @override
  void initState() {
    super.initState();
    _doctorFuture = FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).get();
    _scheduleFuture = FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).collection('schedules').get();
  }

  void updateLocation(String name, String address) {
    if (mounted) {
      setState(() {
        hName = name;
        hAddress = address;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FutureBuilder<DocumentSnapshot>(
        future: _doctorFuture,
        builder: (context, doctorSnapshot) {
          if (!doctorSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = doctorSnapshot.data!.data() as Map<String, dynamic>;
          final List hospitalsList = data['hospitalsList'] ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .where('doctorId', isEqualTo: widget.doctorId)
                .snapshots(),
            builder: (context, reviewsSnapshot) {
              final reviews = reviewsSnapshot.data?.docs ?? [];
              
              double averageRating = 0.0;
              if (reviews.isNotEmpty) {
                final sum = reviews.map((r) {
                  final rData = r.data() as Map<String, dynamic>;
                  return (rData['rating'] as num?)?.toDouble() ?? 0.0;
                }).reduce((a, b) => a + b);
                averageRating = sum / reviews.length;
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .where('doctorId', isEqualTo: widget.doctorId)
                    .snapshots(),
                builder: (context, appointmentsSnapshot) {
                  final appointments = appointmentsSnapshot.data?.docs ?? [];
                  final uniquePatients = appointments.map((a) {
                    final aData = a.data() as Map<String, dynamic>;
                    return aData['patientUid'] ?? '';
                  }).where((uid) => uid.isNotEmpty).toSet().length;

                  return FutureBuilder<QuerySnapshot>(
                    future: _scheduleFuture,
                    builder: (context, scheduleSnapshot) {
                      List<Map<String, dynamic>> scheduleList = [];
                      if (scheduleSnapshot.hasData) {
                        scheduleList = scheduleSnapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                      }

                      return CustomScrollView(
                        slivers: [
                          // Creative SliverAppBar with Floating Glassmorphic Effect
                          SliverAppBar(
                            expandedHeight: 320,
                            pinned: true,
                            backgroundColor: const Color(0xFF2563EB),
                            iconTheme: const IconThemeData(color: Colors.white),
                            flexibleSpace: FlexibleSpaceBar(
                              background: Stack(
                                fit: StackFit.expand,
                                children: [
                                  data['profileImageUrl'] != null && data['profileImageUrl'].toString().isNotEmpty
                                      ? Image.network(data['profileImageUrl'], fit: BoxFit.cover)
                                      : Container(
                                          color: Colors.blue.shade100,
                                          child: const Icon(Icons.person, size: 100, color: Colors.blue),
                                        ),
                                  // Dark overlay at the bottom for readability
                                  Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.transparent, Colors.black54],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                  // Doctor Info floating in bottom banner
                                  Positioned(
                                    bottom: 16,
                                    left: 16,
                                    right: 16,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Dr. ${data['name'] ?? ''}',
                                          style: const TextStyle(
                                            fontSize: 24, 
                                            fontWeight: FontWeight.bold, 
                                            color: Colors.white,
                                            shadows: [Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2563EB).withValues(alpha: 0.8),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                data['specialization'] ?? 'Specialist',
                                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.star, color: Colors.amber, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              averageRating > 0 ? averageRating.toStringAsFixed(1) : '0.0',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            Text(
                                              ' (${reviews.length} reviews)',
                                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
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
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Stats boxes in modern row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatBox(
                                          value: '${data['experience'] ?? 0}+ Yrs',
                                          label: 'Experience',
                                          icon: Icons.work_history_outlined,
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatBox(
                                          value: uniquePatients > 0 ? '$uniquePatients+' : '0+',
                                          label: 'Patients',
                                          icon: Icons.people_outline,
                                          color: Colors.green.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatBox(
                                          value: averageRating > 0 ? averageRating.toStringAsFixed(1) : '0.0',
                                          label: 'Rating',
                                          icon: Icons.star_outline_rounded,
                                          color: Colors.amber.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // About doctor
                                  Text("About Doctor", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                  const SizedBox(height: 8),
                                  Text(
                                    data['aboutMe'] ?? "No description available.",
                                    style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, height: 1.5, fontSize: 14),
                                  ),
                                  const SizedBox(height: 24),

                                  // Location info card
                                  Text("Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade100),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blue.shade50,
                                        child: const Icon(Icons.location_on, color: Colors.blue),
                                      ),
                                      title: Text(hName, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, fontSize: 15)),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(hAddress, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Next availability
                                  Text("Next Availability", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                  const SizedBox(height: 12),
                                  ScheduleSection(
                                    scheduleList: scheduleList,
                                    hospitalsList: hospitalsList,
                                    onDateSelected: updateLocation,
                                  ),
                                  const SizedBox(height: 24),

                                  // Patient reviews
                                  _buildReviewsSection(reviews, doctorName: data['name'] ?? ''),
                                  const SizedBox(height: 30),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          border: Border(top: BorderSide(color: isDark ? const Color(0xFF1E293B) : Colors.transparent)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              final String patientUid = FirebaseAuth.instance.currentUser?.uid ?? "";
              if (patientUid.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelectSlotPage(
                      doctorId: widget.doctorId,
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
              backgroundColor: const Color(0xFF2563EB),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Book Appointment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection(List<QueryDocumentSnapshot> reviews, {required String doctorName}) {
    final double avgRating = reviews.isNotEmpty
        ? (reviews.fold<double>(0.0, (acc, r) => acc + ((r.data() as Map<String, dynamic>)['rating'] as num? ?? 5.0).toDouble()) / reviews.length)
        : 0.0;

    final int recommendCount = reviews.where((r) {
      final data = r.data() as Map<String, dynamic>;
      return data['wouldRecommend'] == true || (data['rating'] as num? ?? 5) >= 4;
    }).length;

    final int recommendPercentage = reviews.isNotEmpty ? ((recommendCount / reviews.length) * 100).round() : 100;
    final String patientUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating Summary Breakdown Banner
        Builder(builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0C4A6E).withValues(alpha: 0.5), const Color(0xFF1E3A8A).withValues(alpha: 0.3)]
                  : [const Color(0xFF0EA5E9).withValues(alpha: 0.08), const Color(0xFF2563EB).withValues(alpha: 0.03)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? const Color(0xFF1D4ED8) : const Color(0xFFBAE6FD)),
          ),
          child: Row(
            children: [
              // Rating big score
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        avgRating > 0 ? avgRating.toStringAsFixed(1) : '5.0',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/ 5.0',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (starIdx) {
                      return Icon(
                        starIdx < (avgRating > 0 ? avgRating.round() : 5) ? Icons.star_rounded : Icons.star_border_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 18,
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${reviews.length} Verified Reviews',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Recommendation & Trust Badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF166534) : const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.thumb_up_rounded, color: Color(0xFF15803D), size: 13),
                        const SizedBox(width: 6),
                        Text(
                          '$recommendPercentage% Recommend',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF0EA5E9), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '100% Real Patients',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
        }),
        const SizedBox(height: 16),

        // Write a Review Button Header Row
        Builder(builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Patient Feedback (${reviews.length})',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            if (patientUid.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => DoctorRatingDialog(
                      doctorId: widget.doctorId,
                      doctorName: doctorName,
                      patientUid: patientUid,
                    ),
                  );
                  setState(() {});
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  side: const BorderSide(color: Color(0xFF0EA5E9)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFF0F9FF),
                ),
                icon: const Icon(Icons.rate_review_rounded, size: 14, color: Color(0xFF0284C7)),
                label: const Text(
                  'Write Review',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                ),
              ),
          ],
        );
        }),
        const SizedBox(height: 12),

        // Review Cards List
        if (reviews.isEmpty)
          Builder(builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Text(
                'No reviews yet. Be the first to leave a review after your visit!',
                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontStyle: FontStyle.italic, fontSize: 13),
              ),
            ),
          );
          })
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final sortedReviews = reviews.toList()
                ..sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['updatedAt'] as Timestamp?;
                  final bTime = bData['updatedAt'] as Timestamp?;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

              final data = sortedReviews[index].data() as Map<String, dynamic>;
              final rating = data['rating'] is num ? (data['rating'] as num).toInt() : 5;
              String rawComment = data['comment']?.toString() ?? '';
              final timestamp = data['updatedAt'] as Timestamp?;
              final patientUid = data['patientUid'] ?? '';

              // Parse tags from data['tags'] or legacy comment string
              List<String> tags = [];
              if (data['tags'] is List) {
                tags = (data['tags'] as List).map((e) => cleanGarbledText(e.toString())).where((t) => t.isNotEmpty).toList();
              } else if (rawComment.contains('(Tags:')) {
                final match = RegExp(r'\(Tags:\s*([^)]+)\)').firstMatch(rawComment);
                if (match != null) {
                  tags = match.group(1)!.split(',').map((t) => cleanGarbledText(t.trim())).where((t) => t.isNotEmpty).toList();
                }
              }

              // Clean comment text by stripping legacy tags suffix & garbled characters
              String cleanComment = cleanGarbledText(rawComment.replaceAll(RegExp(r'\s*\(Tags:.*?\)$'), '').trim());
              if (cleanComment.isEmpty) {
                cleanComment = 'Great consultation & compassionate care.';
              }

              String formattedDate = '';
              if (timestamp != null) {
                formattedDate = DateFormat('MMM d, yyyy').format(timestamp.toDate());
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('patients').doc(patientUid).get(),
                builder: (context, patientSnapshot) {
                  final patientData = patientSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                  final String patientName = patientData['name'] ?? 'Patient';
                  final String? patientImageUrl = patientData['profileImageUrl'];

                  final isDarkCard = Theme.of(context).brightness == Brightness.dark;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDarkCard ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDarkCard ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDarkCard ? 0.2 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Avatar, Name, Verified Badge, Date
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFFE0F2FE),
                                backgroundImage: patientImageUrl != null && patientImageUrl.isNotEmpty
                                    ? NetworkImage(patientImageUrl)
                                    : null,
                                child: patientImageUrl == null || patientImageUrl.isEmpty
                                    ? const Icon(Icons.person_rounded, size: 20, color: Color(0xFF0EA5E9))
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            patientName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: isDarkCard ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                         const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDarkCard ? const Color(0xFF052E16) : const Color(0xFFECFDF5),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: isDarkCard ? const Color(0xFF166534) : const Color(0xFFA7F3D0)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.verified_rounded, size: 11, color: Color(0xFF10B981)),
                                              const SizedBox(width: 3),
                                              Text(
                                                'Verified',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDarkCard ? const Color(0xFF4ADE80) : const Color(0xFF047857),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Row(
                                          children: List.generate(5, (starIdx) {
                                            return Icon(
                                              starIdx < rating ? Icons.star_rounded : Icons.star_border_rounded,
                                              color: const Color(0xFFF59E0B),
                                              size: 15,
                                            );
                                          }),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$rating.0',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (formattedDate.isNotEmpty)
                                Text(
                                  formattedDate,
                                  style: TextStyle(color: isDarkCard ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w500),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Comment Text
                          Text(
                            cleanComment,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDarkCard ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B),
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          // Feedback Tag Chips (if available)
                          if (tags.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDarkCard ? const Color(0xFF0C4A6E) : const Color(0xFFF0F9FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isDarkCard ? const Color(0xFF0369A1) : const Color(0xFFBAE6FD)),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkCard ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildStatBox({
    required String value, 
    required String label, 
    required IconData icon, 
    required Color color
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class ScheduleSection extends StatefulWidget {
  final List<Map<String, dynamic>> scheduleList;
  final List<dynamic> hospitalsList;
  final Function(String, String) onDateSelected;
  const ScheduleSection({super.key, required this.scheduleList, required this.hospitalsList, required this.onDateSelected});

  @override
  State<ScheduleSection> createState() => _ScheduleSectionState();
}

class _ScheduleSectionState extends State<ScheduleSection> {
  DateTime? selectedDate;

  String getAddressFromName(String hospitalName) {
    final hospital = widget.hospitalsList.firstWhere(
      (h) => h['hospitalName'] == hospitalName,
      orElse: () => null,
    );
    if (hospital != null && hospital['hospitalAddresses'] != null && hospital['hospitalAddresses'].isNotEmpty) {
      return hospital['hospitalAddresses'][0].toString();
    }
    return "Address not available";
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().add(Duration(days: index));
          String dayName = DateFormat('EEEE').format(date);
          final daySchedule = widget.scheduleList.firstWhere((s) => s['day']?.toString().toLowerCase() == dayName.toLowerCase(), orElse: () => {});

          if (daySchedule.isEmpty) return const SizedBox.shrink();

          if (selectedDate == null && index == 0) {
            selectedDate = date;
            String hName = daySchedule['hospitalName'] ?? "Clinic";
            Future.microtask(() => widget.onDateSelected(hName, getAddressFromName(hName)));
          }

          bool isSelected = selectedDate != null && DateFormat('yyyy-MM-dd').format(selectedDate!) == DateFormat('yyyy-MM-dd').format(date);

          return GestureDetector(
            onTap: () {
              setState(() { selectedDate = date; });
              String hName = daySchedule['hospitalName'] ?? "Clinic";
              widget.onDateSelected(hName, getAddressFromName(hName));
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: _ScheduleBox(DateFormat('EEE').format(date).toUpperCase(), DateFormat('dd').format(date), "${daySchedule['maxPatients'] ?? 0} Slots", isSelected),
            ),
          );
        },
      ),
    );
  }
}

class _ScheduleBox extends StatelessWidget {
  final String day, date, slots;
  final bool isSelected;
  const _ScheduleBox(this.day, this.date, this.slots, this.isSelected);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 65,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF2563EB)
            : (isDark ? const Color(0xFF1E293B) : Colors.white),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSelected ? [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ] : [
          if (isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(day, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : Colors.grey), fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(date, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87))),
          const SizedBox(height: 4),
          Text(slots, style: TextStyle(fontSize: 8, color: isSelected ? Colors.white70 : (isDark ? const Color(0xFF64748B) : Colors.grey.shade600), fontWeight: FontWeight.w600))
        ],
      ),
    );
  }
}