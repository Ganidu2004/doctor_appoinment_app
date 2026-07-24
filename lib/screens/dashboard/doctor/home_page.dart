import 'package:appoinment_app/screens/dashboard/doctor/widgets/appoinment_card.dart';
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

class _DoctorHomePageState extends State<DoctorHomePage> with SingleTickerProviderStateMixin {
  final DateFormat _dateFormat = DateFormat('MMMM d, yyyy');
  bool _localDutyStatus = true;
  bool _isInit = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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

  Future<void> _toggleDutyStatus(String uid, bool currentStatus) async {
    final nextStatus = !currentStatus;
    setState(() {
      _localDutyStatus = nextStatus;
      _isInit = false;
    });
    try {
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .set({'isOnDuty': nextStatus}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating duty status: $e');
    }
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final doctorName = widget.doctorData['name']?.toString() ?? 'Doctor';

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

        // Custom consultation data for the last 7 days (trend chart)
        final dailyCounts = List<double>.filled(7, 0.0);
        final now = DateTime.now();

        for (final doc in appointments) {
          final data = doc.data() as Map<String, dynamic>;

          final pid = data['patientUid']?.toString() ?? '';
          if (pid.isNotEmpty) uniquePatients.add(pid);

          final status = _normalizeStatus(data['status']?.toString() ?? '');

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

          // Populate last 7 days consultation counts
          final apptDateStr = data['date']?.toString();
          if (apptDateStr != null) {
            try {
              final parsed = _dateFormat.parseLoose(apptDateStr);
              final difference = now.difference(parsed).inDays;
              if (difference >= 0 && difference < 7) {
                dailyCounts[6 - difference] += 1.0;
              }
            } catch (_) {}
          }
        }

        // Standard fallback if there is no data to plot
        bool hasTrendData = dailyCounts.any((c) => c > 0);
        final List<double> finalTrendData = hasTrendData ? dailyCounts : [3.0, 5.0, 4.0, 6.0, 8.0, 5.0, 7.0];

        final totalConsults = appointments.length;

        final upcoming = appointments.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = _normalizeStatus(data['status']?.toString() ?? '');
          return status == 'PENDING';
        }).toList();

        upcoming.sort((a, b) {
          final ad = _appointmentDateTime(a.data() as Map<String, dynamic>);
          final bd = _appointmentDateTime(b.data() as Map<String, dynamic>);
          return ad.compareTo(bd);
        });

        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔵 CUSTOM GRADIENT HEADER WITH ONLINE STATUS SWITCHER
                StreamBuilder<DocumentSnapshot>(
                  stream: _doctorStream(user.uid),
                  builder: (context, docSnap) {
                    final data = docSnap.data?.data() as Map<String, dynamic>?;
                    final imageUrl = data?['imageUrl'] ?? data?['profileImageUrl'] ?? '';
                    final specialization = data?['specialization'] ?? 'Specialist';
                    
                    if (data != null && data.containsKey('isOnDuty') && _isInit) {
                      _localDutyStatus = data['isOnDuty'] == true;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _localDutyStatus ? const Color(0xFF10B981) : Colors.amber,
                                        width: 2.5,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                                      backgroundImage: imageUrl.isNotEmpty
                                          ? NetworkImage(imageUrl)
                                          : null,
                                      child: imageUrl.isEmpty
                                          ? const Icon(Icons.person, color: Colors.white, size: 28)
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, child) {
                                        return Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: _localDutyStatus ? const Color(0xFF10B981) : Colors.amber,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFF0F172A),
                                              width: 1.5,
                                            ),
                                            boxShadow: _localDutyStatus
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(0xFF10B981)
                                                          .withValues(alpha: 0.6 * _pulseController.value),
                                                      blurRadius: 6,
                                                      spreadRadius: 2.5,
                                                    )
                                                  ]
                                                : [],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getGreeting(),
                                      style: TextStyle(
                                        color: Colors.tealAccent.shade400,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Dr. $doctorName',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      specialization,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white10, height: 24, thickness: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _localDutyStatus ? Icons.check_circle : Icons.do_not_disturb_on,
                                    color: _localDutyStatus ? const Color(0xFF10B981) : Colors.amber,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _localDutyStatus ? 'Active on Duty' : 'Away / Offline',
                                    style: TextStyle(
                                      color: _localDutyStatus ? const Color(0xFF10B981) : Colors.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => _toggleDutyStatus(user.uid, _localDutyStatus),
                                child: Container(
                                  width: 85,
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: _localDutyStatus 
                                        ? const Color(0xFF10B981).withValues(alpha: 0.15) 
                                        : Colors.white.withValues(alpha: 0.08),
                                    border: Border.all(
                                      color: _localDutyStatus 
                                          ? const Color(0xFF10B981).withValues(alpha: 0.4) 
                                          : Colors.white24,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      AnimatedAlign(
                                        duration: const Duration(milliseconds: 250),
                                        curve: Curves.easeInOut,
                                        alignment: _localDutyStatus 
                                            ? Alignment.centerRight 
                                            : Alignment.centerLeft,
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _localDutyStatus ? const Color(0xFF10B981) : Colors.grey.shade400,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.2),
                                                blurRadius: 4,
                                              )
                                            ],
                                          ),
                                          child: Icon(
                                            _localDutyStatus ? Icons.power_settings_new : Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: _localDutyStatus ? Alignment.centerLeft : Alignment.centerRight,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: Text(
                                            _localDutyStatus ? 'ON' : 'OFF',
                                            style: TextStyle(
                                              color: _localDutyStatus ? Colors.white : Colors.grey.shade400,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),

                /// 🔵 DYNAMIC ACTION QUICK BUTTONS ROW
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildQuickAction(
                        icon: Icons.calendar_today_rounded,
                        label: 'Schedule',
                        color: Colors.blue,
                        onTap: () {},
                      ),
                      _buildQuickAction(
                        icon: Icons.history_edu_rounded,
                        label: 'Write Rx',
                        color: Colors.teal,
                        onTap: () {},
                      ),
                      _buildQuickAction(
                        icon: Icons.people_outline_rounded,
                        label: 'Patients',
                        color: Colors.indigo,
                        onTap: () {},
                      ),
                      _buildQuickAction(
                        icon: Icons.analytics_outlined,
                        label: 'Reports',
                        color: Colors.purple,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// 🔵 ANALYTICS CHART SECTION
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Consultation Trend',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Activity from the last 7 days',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.trending_up, color: Color(0xFF0D9488), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Weekly',
                                  style: TextStyle(
                                    color: Color(0xFF0D9488),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: CurveChartPainter(finalTrendData),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// 🔵 INTERACTIVE STATS / MINI SUMMARY GRID
                Row(
                  children: [
                    Expanded(
                      child: _buildInteractiveStatCard(
                        icon: Icons.group_rounded,
                        title: 'Total Patients',
                        value: uniquePatients.length.toString(),
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildInteractiveStatCard(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Total Consults',
                        value: totalConsults.toString(),
                        color: Colors.indigo.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /// 🔵 TODAY'S STATUS PILLS
                const Text(
                  "Today's Overview",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SummaryMiniCard(
                        icon: Icons.check_circle_outline,
                        count: completedCount.toString(),
                        label: 'COMPLETED',
                        color: const Color(0xFF10B981)),
                    SummaryMiniCard(
                        icon: Icons.watch_later_outlined,
                        count: pendingCount.toString(),
                        label: 'PENDING',
                        color: Colors.orange),
                    SummaryMiniCard(
                        icon: Icons.cancel_outlined,
                        count: cancelledCount.toString(),
                        label: 'CANCELLED',
                        color: Colors.red),
                  ],
                ),

                const SizedBox(height: 28),

                /// 🔵 UPCOMING TIMELINE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Upcoming Timeline',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Today ($todayCount)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (upcoming.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 36, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'No upcoming appointments today',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: upcoming.length,
                    itemBuilder: (context, index) {
                      final doc = upcoming[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final status = _normalizeStatus(data['status']?.toString() ?? '');
                      final bool isLast = index == upcoming.length - 1;

                      return _buildTimelineItem(
                        isLast: isLast,
                        time: data['time']?.toString() ?? '10:00 AM',
                        child: AppointmentCard(
                          name: data['patientName'] ?? 'Patient',
                          type: data['type'] ?? 'Consultation',
                          time: '${data['date']} • ${data['time']}',
                          status: status,
                          reason: data['notes']?.toString(),
                          onAccept: status != 'CONFIRMED'
                              ? () => _confirmAndUpdate(doc.id, 'CONFIRMED')
                              : null,
                          onDecline: status != 'CANCELLED'
                              ? () => _confirmAndUpdate(doc.id, 'CANCELLED')
                              : null,
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required Widget child,
    required String time,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(height: 22),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0D9488),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 1.5,
                  )
                ],
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 150,
                color: Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 6),
                child: Text(
                  time,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

class CurveChartPainter extends CustomPainter {
  final List<double> dataPoints;
  CurveChartPainter(this.dataPoints);

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFF0D9488)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;

    final dotOuterPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    double stepX = size.width / (dataPoints.length - 1);
    double maxY = dataPoints.reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 1;

    double getX(int index) => index * stepX;
    double getY(double val) => size.height - (val / maxY * (size.height - 20)) - 10;

    path.moveTo(getX(0), getY(dataPoints[0]));
    fillPath.moveTo(getX(0), size.height);
    fillPath.lineTo(getX(0), getY(dataPoints[0]));

    for (int i = 0; i < dataPoints.length - 1; i++) {
      double x1 = getX(i);
      double y1 = getY(dataPoints[i]);
      double x2 = getX(i + 1);
      double y2 = getY(dataPoints[i + 1]);
      double cx = (x1 + x2) / 2;

      path.cubicTo(cx, y1, cx, y2, x2, y2);
      fillPath.cubicTo(cx, y1, cx, y2, x2, y2);
    }

    fillPath.lineTo(getX(dataPoints.length - 1), size.height);
    fillPath.close();

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      double y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw fill area
    var rect = Offset.zero & size;
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0D9488).withValues(alpha: 0.3),
        const Color(0xFF0D9488).withValues(alpha: 0.0),
      ],
    ).createShader(rect);
    canvas.drawPath(fillPath, paint);

    // Draw curve line
    canvas.drawPath(path, linePaint);

    // Draw glowing dots
    for (int i = 0; i < dataPoints.length; i++) {
      double x = getX(i);
      double y = getY(dataPoints[i]);
      canvas.drawCircle(Offset(x, y), 8, dotOuterPaint);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CurveChartPainter oldDelegate) =>
      oldDelegate.dataPoints != dataPoints;
}