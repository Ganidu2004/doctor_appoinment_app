import 'package:appoinment_app/screens/dashboard/appoiment/appoiment_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                                  const Text("About Doctor", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(height: 8),
                                  Text(
                                    data['aboutMe'] ?? "No description available.",
                                    style: TextStyle(color: Colors.grey.shade600, height: 1.5, fontSize: 14),
                                  ),
                                  const SizedBox(height: 24),

                                  // Location info card
                                  const Text("Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
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
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blue.shade50,
                                        child: const Icon(Icons.location_on, color: Colors.blue),
                                      ),
                                      title: Text(hName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(hAddress, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Next availability
                                  const Text("Next Availability", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(height: 12),
                                  ScheduleSection(
                                    scheduleList: scheduleList,
                                    hospitalsList: hospitalsList,
                                    onDateSelected: updateLocation,
                                  ),
                                  const SizedBox(height: 24),

                                  // Patient reviews
                                  const Text("Patient Reviews", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(height: 10),
                                  _buildReviewsSection(reviews),
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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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

  Widget _buildReviewsSection(List<QueryDocumentSnapshot> reviews) {
    if (reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          "No reviews yet. Be the first to leave a review!",
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedReviews.length,
      itemBuilder: (context, index) {
        final data = sortedReviews[index].data() as Map<String, dynamic>;
        final rating = data['rating'] is num ? (data['rating'] as num).toInt() : 5;
        final comment = data['comment']?.toString() ?? '';
        final timestamp = data['updatedAt'] as Timestamp?;
        final patientUid = data['patientUid'] ?? '';
        
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

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.015),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: patientImageUrl != null && patientImageUrl.isNotEmpty 
                              ? NetworkImage(patientImageUrl) 
                              : null,
                          child: patientImageUrl == null || patientImageUrl.isEmpty 
                              ? const Icon(Icons.person, size: 18, color: Colors.blue) 
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patientName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                              ),
                              Row(
                                children: List.generate(5, (starIdx) {
                                  return Icon(
                                    starIdx < rating ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 13,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        if (formattedDate.isNotEmpty)
                          Text(
                            formattedDate,
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      comment.isNotEmpty ? comment : 'No comment provided.',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
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

  Widget _buildStatBox({
    required String value, 
    required String label, 
    required IconData icon, 
    required Color color
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
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
    return Container(
      width: 65,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2563EB) : Colors.white, 
        border: Border.all(
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade200, 
          width: 1.5,
        ), 
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSelected ? [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(day, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(date, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(slots, style: TextStyle(fontSize: 8, color: isSelected ? Colors.white70 : Colors.grey.shade600, fontWeight: FontWeight.w600))
        ],
      ),
    );
  }
}