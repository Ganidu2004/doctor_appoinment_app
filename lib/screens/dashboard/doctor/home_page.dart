import 'package:appoinment_app/screens/dashboard/doctor/widgets/appoinment_card.dart';
import 'package:appoinment_app/screens/dashboard/doctor/widgets/stat_card.dart';
import 'package:appoinment_app/screens/dashboard/doctor/widgets/summary_mini_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:appoinment_app/services/notification_services.dart';

class DoctorHomePage extends StatefulWidget {
  final Map<String, dynamic> doctorData;

  const DoctorHomePage({
    super.key,
    required this.doctorData,
  });

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  final DateFormat _dateFormat = DateFormat('MMMM d, yyyy');

  Stream<QuerySnapshot> _appointmentsStream(String doctorUid) {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorUid)
        .snapshots();
  }

  Stream<DocumentSnapshot> _doctorStream(String uid) {
    return FirebaseFirestore.instance
        .collection('doctors')
        .doc(uid)
        .snapshots();
  }

  String _normalizeStatus(String status) {
    final upper = status.toUpperCase();
    if (upper.contains('CANCEL')) return 'CANCELLED';
    if (upper.contains('COMPLET')) return 'COMPLETED';
    if (upper.contains('CONFIRM')) return 'CONFIRMED';
    if (upper.contains('PEND') || upper == 'BOOKED') return 'PENDING';
    return status;
  }

  bool _isToday(String? appointmentDate) {
    if (appointmentDate == null) return false;
    try {
      final parsed = _dateFormat.parseLoose(appointmentDate);
      final now = DateTime.now();
      return parsed.year == now.year &&
          parsed.month == now.month &&
          parsed.day == now.day;
    } catch (_) {
      return false;
    }
  }

  DateTime _appointmentDateTime(Map<String, dynamic> data) {
    final date = data['date']?.toString();
    final time = data['time']?.toString();
    try {
      if (date != null && date.isNotEmpty) {
        final parsedDate = _dateFormat.parseLoose(date);
        if (time != null && time.isNotEmpty) {
          final parsedTime = DateFormat('hh:mm a').parseLoose(time);
          return DateTime(parsedDate.year, parsedDate.month,
              parsedDate.day, parsedTime.hour, parsedTime.minute);
        }
        return parsedDate;
      }
    } catch (_) {}
    return DateTime.now();
  }

  Future<void> _updateAppointmentStatus(
      String appointmentId, String status) async {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _confirmAndUpdate(
      String appointmentId, String newStatus) async {
    final actionLabel =
        newStatus == 'CONFIRMED' ? 'Accept' : 'Decline';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionLabel appointment?'),
        content:
            Text('Are you sure you want to $actionLabel this appointment?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes')),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;

    try {
      await _updateAppointmentStatus(appointmentId, newStatus);
      
      try {
        if (newStatus == 'CONFIRMED') {
          await NotificationService().showNotification(
            id: 301,
            title: 'Appointment Accepted',
            body: 'You have accepted the appointment successfully.',
          );
        } else if (newStatus == 'CANCELLED') {
          await NotificationService().showNotification(
            id: 302,
            title: 'Appointment Cancelled',
            body: 'You have cancelled the appointment successfully.',
          );
        }
      } catch (err) {
        debugPrint('Notification error: $err');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final doctorName =
        widget.doctorData['name']?.toString() ?? 'Doctor';

    if (user == null) {
      return const Center(
        child: Text('Please sign in to view dashboard.'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _appointmentsStream(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final appointments = snapshot.data!.docs;

        final uniquePatients = <String>{};
        int todayCount = 0;
        int completedCount = 0;
        int pendingCount = 0;
        int cancelledCount = 0;

        for (final doc in appointments) {
          final data = doc.data() as Map<String, dynamic>;

          final pid = data['patientUid']?.toString() ?? '';
          if (pid.isNotEmpty) uniquePatients.add(pid);

          final status =
              _normalizeStatus(data['status']?.toString() ?? '');

          if (_isToday(data['date']?.toString())) {
            todayCount++;
          }

          if (status == 'COMPLETED') {
            completedCount++;
          } else if (status == 'PENDING') {
            pendingCount++;
          } else if (status == 'CANCELLED') {
            cancelledCount++;
          }
        }

        final totalConsults = appointments.length;

        final upcoming = appointments.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status =
              _normalizeStatus(data['status']?.toString() ?? '');
          return status == 'PENDING';
        }).toList();

        upcoming.sort((a, b) {
          final ad = _appointmentDateTime(
              a.data() as Map<String, dynamic>);
          final bd = _appointmentDateTime(
              b.data() as Map<String, dynamic>);
          return ad.compareTo(bd);
        });

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔵 DOCTOR HEADER WITH IMAGE (Layout 4 Glass design)
                StreamBuilder<DocumentSnapshot>(
                  stream: _doctorStream(user.uid),
                  builder: (context, docSnap) {
                    final data = docSnap.data?.data() as Map<String, dynamic>?;
                    final imageUrl = data?['imageUrl'] ?? data?['profileImageUrl'] ?? '';
                    final specialization = data?['specialization'] ?? 'Specialist';
                    final String timeStr = DateFormat('h:mm a').format(DateTime.now());

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF10B981)], // Teal to Green gradient matching Screen 5
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        timeStr,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.battery_charging_full,
                                            color: Colors.white.withValues(alpha: 0.85),
                                            size: 13,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "84%",
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.85),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.15),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.grid_view_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Dr. $doctorName',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "$specialization — Doctor Portal",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.8),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.6),
                                                width: 2,
                                              ),
                                            ),
                                            child: CircleAvatar(
                                              radius: 22,
                                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                                              backgroundImage: imageUrl.isNotEmpty
                                                  ? NetworkImage(imageUrl)
                                                  : null,
                                              child: imageUrl.isEmpty
                                                  ? const Icon(Icons.person, color: Colors.white, size: 22)
                                                  : null,
                                            ),
                                          ),
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
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
                ),

                const SizedBox(height: 6),

                Text(
                  'You have $todayCount appointments today.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),

                const SizedBox(height: 24),

                /// STATS
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.05,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  children: [
                    StatCard(
                        icon: Icons.group,
                        title: 'PATIENTS',
                        value: uniquePatients.length.toString(),
                        sub:
                            '+${(uniquePatients.length / 10).round()}',
                        iconColor: Colors.blue),
                    StatCard(
                        icon: Icons.chat,
                        title: 'CONSULTS',
                        value: totalConsults.toString(),
                        sub: '',
                        iconColor: Colors.indigo),
                    StatCard(
                        icon: Icons.check_circle,
                        title: 'COMPLETED',
                        value: completedCount.toString(),
                        sub: '',
                        iconColor: Colors.green),
                    StatCard(
                        icon: Icons.access_time,
                        title: 'PENDING',
                        value: pendingCount.toString(),
                        sub: '',
                        iconColor: Colors.orange),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  "Today's Summary",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SummaryMiniCard(
                        icon: Icons.check,
                        count: completedCount.toString(),
                        label: 'DONE',
                        color: Colors.green),
                    SummaryMiniCard(
                        icon: Icons.pending,
                        count: pendingCount.toString(),
                        label: 'PENDING',
                        color: Colors.orange),
                    SummaryMiniCard(
                        icon: Icons.cancel,
                        count: cancelledCount.toString(),
                        label: 'CANCEL',
                        color: Colors.red),
                  ],
                ),

                const SizedBox(height: 24),

                /// UPCOMING
                const Text(
                  'Upcoming Appointments',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                if (upcoming.isEmpty)
                  const Center(
                      child: Text('No upcoming appointments'))
                else
                  Column(
                    children: upcoming.map((doc) {
                      final data =
                          doc.data() as Map<String, dynamic>;

                      final status = _normalizeStatus(
                          data['status']?.toString() ?? '');

                      return AppointmentCard(
                        name:
                            data['patientName'] ?? 'Patient',
                        type: data['type'] ?? 'Consultation',
                        time:
                            '${data['date']} • ${data['time']}',
                        status: status,
                        reason: data['notes']?.toString(),
                        onAccept: status != 'CONFIRMED'
                            ? () => _confirmAndUpdate(
                                doc.id, 'CONFIRMED')
                            : null,
                        onDecline: status != 'CANCELLED'
                            ? () => _confirmAndUpdate(
                                doc.id, 'CANCELLED')
                            : null,
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }
}