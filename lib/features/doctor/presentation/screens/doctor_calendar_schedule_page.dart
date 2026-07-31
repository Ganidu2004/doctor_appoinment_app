import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DoctorCalendarSchedulePage extends StatefulWidget {
  const DoctorCalendarSchedulePage({super.key});

  @override
  State<DoctorCalendarSchedulePage> createState() => _DoctorCalendarSchedulePageState();
}

class _DoctorCalendarSchedulePageState extends State<DoctorCalendarSchedulePage> {
  String _currentViewMode = 'Weekly'; // 'Daily', 'Weekly', 'Monthly'
  DateTime _selectedDate = DateTime.now();

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  bool _isDateMatch(String dateStr, DateTime targetDate) {
    if (dateStr.trim().isEmpty) return false;

    final targetFormatted = DateFormat('yyyy-MM-dd').format(targetDate);
    if (dateStr == targetFormatted || dateStr.contains(targetFormatted)) return true;

    // Check alternative date formats
    final altFormats = [
      DateFormat('yyyy-M-d').format(targetDate),
      DateFormat('dd/MM/yyyy').format(targetDate),
      DateFormat('MM/dd/yyyy').format(targetDate),
      DateFormat('d/M/yyyy').format(targetDate),
      DateFormat('MMM d, yyyy').format(targetDate),
      DateFormat('MMMM d, yyyy').format(targetDate),
    ];

    for (var alt in altFormats) {
      if (dateStr == alt || dateStr.contains(alt)) return true;
    }

    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null && _isSameDay(parsed, targetDate)) return true;
    } catch (_) {}

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Schedule & Calendar')),
        body: const Center(child: Text('Please sign in as a doctor.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Calendar & Schedule View',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded, color: Color(0xFF0EA5E9)),
            onPressed: () => setState(() => _selectedDate = DateTime.now()),
            tooltip: 'Today',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('patients').snapshots(),
        builder: (context, patientsSnapshot) {
          final Map<String, Map<String, dynamic>> patientsMap = {};
          if (patientsSnapshot.hasData) {
            for (var doc in patientsSnapshot.data!.docs) {
              patientsMap[doc.id] = doc.data() as Map<String, dynamic>;
            }
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('doctors')
                .doc(user.uid)
                .collection('schedules')
                .snapshots(),
            builder: (context, schedulesSnapshot) {
              final scheduleDocs = schedulesSnapshot.data?.docs ?? [];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .where('doctorId', isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, appointmentsSnapshot) {
                  if (appointmentsSnapshot.connectionState == ConnectionState.waiting &&
                      !appointmentsSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)));
                  }

                  final appointmentDocs = appointmentsSnapshot.data?.docs ?? [];

                  return Column(
                    children: [
                      // View Mode Selector (Daily, Weekly, Monthly)
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: ['Daily', 'Weekly', 'Monthly'].map((mode) {
                              final isSelected = _currentViewMode == mode;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _currentViewMode = mode),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      mode == 'Daily'
                                          ? 'Daily 📅'
                                          : mode == 'Weekly'
                                              ? 'Weekly 🗓️'
                                              : 'Monthly 📆',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // Date Navigator Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF334155)),
                              onPressed: () {
                                setState(() {
                                  if (_currentViewMode == 'Daily') {
                                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                                  } else if (_currentViewMode == 'Weekly') {
                                    _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                                  } else {
                                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
                                  }
                                });
                              },
                            ),
                            Text(
                              _currentViewMode == 'Daily'
                                  ? DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)
                                  : _currentViewMode == 'Weekly'
                                      ? 'Week of ${DateFormat('MMM d').format(_selectedDate.subtract(Duration(days: _selectedDate.weekday - 1)))} - ${DateFormat('MMM d, yyyy').format(_selectedDate.add(Duration(days: 7 - _selectedDate.weekday)))}'
                                      : DateFormat('MMMM yyyy').format(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F172A)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF334155)),
                              onPressed: () {
                                setState(() {
                                  if (_currentViewMode == 'Daily') {
                                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                                  } else if (_currentViewMode == 'Weekly') {
                                    _selectedDate = _selectedDate.add(const Duration(days: 7));
                                  } else {
                                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // Content Body
                      Expanded(
                        child: _currentViewMode == 'Daily'
                            ? _buildDailyView(appointmentDocs, scheduleDocs, patientsMap)
                            : _currentViewMode == 'Weekly'
                                ? _buildWeeklyView(appointmentDocs, scheduleDocs, patientsMap)
                                : _buildMonthlyView(appointmentDocs),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDailyView(
    List<QueryDocumentSnapshot> apptDocs,
    List<QueryDocumentSnapshot> scheduleDocs,
    Map<String, Map<String, dynamic>> patientsMap,
  ) {
    final dayOfWeek = DateFormat('EEEE').format(_selectedDate);

    // Matching shifts for this day of week
    final activeShifts = scheduleDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final day = (data['day'] ?? '').toString();
      final isActive = data['isActive'] ?? true;
      final disabledDates = List<String>.from(data['disabledDates'] ?? []);
      final targetDateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
      return day.toLowerCase() == dayOfWeek.toLowerCase() && isActive && !disabledDates.contains(targetDateKey);
    }).toList();

    // Matching appointments for this date
    final dayAppointments = apptDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final dateVal = (data['date'] ?? '').toString();
      return _isDateMatch(dateVal, _selectedDate);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shift Summary Section
          if (activeShifts.isNotEmpty) ...[
            const Text('Working Shifts Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            ...activeShifts.map((sDoc) {
              final sData = sDoc.data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital_rounded, color: Color(0xFF0284C7), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sData['hospitalName'] ?? 'Hospital / Clinic',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "${sData['startTime']} - ${sData['endTime']} • Max ${sData['maxPatients']} Patients",
                            style: const TextStyle(fontSize: 12, color: Color(0xFF0369A1), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          Text(
            'Patient Appointments (${dayAppointments.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),

          if (dayAppointments.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                    child: const Icon(Icons.event_available_rounded, size: 36, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 12),
                  const Text('No Appointments Scheduled', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  Text(
                    'No patient bookings found for ${DateFormat('MMM d, yyyy').format(_selectedDate)}.',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                  ),
                ],
              ),
            )
          else
            ...dayAppointments.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final patientUid = (data['patientUid'] ?? '').toString();
              final patientData = patientsMap[patientUid] ?? {};

              final String patientName = (data['patientName'] ?? patientData['name'] ?? 'Patient').toString();
              final String profileImg = (data['profileImageUrl'] ?? patientData['profileImageUrl'] ?? '').toString();
              final String patientPhone = (patientData['phone'] ?? patientData['contact'] ?? data['patientPhone'] ?? '').toString();
              final String time = (data['time'] ?? '09:00 AM').toString();
              final String status = (data['status'] ?? 'Booked').toString();
              final String hospital = (data['hospitalName'] ?? data['hospital'] ?? 'Clinic').toString();
              final String paymentMethod = (data['paymentMethod'] ?? 'Online').toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFE0F2FE),
                          backgroundImage: profileImg.isNotEmpty ? NetworkImage(profileImg) : null,
                          child: profileImg.isEmpty
                              ? const Icon(Icons.person_rounded, color: Color(0xFF0EA5E9), size: 24)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 4),
                                  Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                                  const SizedBox(width: 8),
                                  Text('• $hospital', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'completed'
                                ? const Color(0xFFECFDF5)
                                : status.toLowerCase().contains('cancel')
                                    ? const Color(0xFFFEF2F2)
                                    : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'completed'
                                  ? const Color(0xFFA7F3D0)
                                  : status.toLowerCase().contains('cancel')
                                      ? const Color(0xFFFECACA)
                                      : const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'completed'
                                  ? const Color(0xFF047857)
                                  : status.toLowerCase().contains('cancel')
                                      ? Colors.redAccent
                                      : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (patientPhone.isNotEmpty) ...[
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.payment_rounded, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(paymentMethod, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF0EA5E9)),
                              const SizedBox(width: 4),
                              Text(
                                patientPhone,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildWeeklyView(
    List<QueryDocumentSnapshot> apptDocs,
    List<QueryDocumentSnapshot> scheduleDocs,
    Map<String, Map<String, dynamic>> patientsMap,
  ) {
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 7,
      itemBuilder: (context, index) {
        final day = startOfWeek.add(Duration(days: index));
        final dayTitle = DateFormat('EEEE, MMM d').format(day);
        final dayOfWeek = DateFormat('EEEE').format(day);
        final targetDateKey = DateFormat('yyyy-MM-dd').format(day);

        // Matching appointments for this day
        final dayAppts = apptDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final d = (data['date'] ?? '').toString();
          return _isDateMatch(d, day);
        }).toList();

        // Matching working shifts for this weekday
        final dayShifts = scheduleDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final d = (data['day'] ?? '').toString();
          final isActive = data['isActive'] ?? true;
          final disabledDates = List<String>.from(data['disabledDates'] ?? []);
          return d.toLowerCase() == dayOfWeek.toLowerCase() && isActive && !disabledDates.contains(targetDateKey);
        }).toList();

        final isToday = _isSameDay(DateTime.now(), day);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isToday ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0), width: isToday ? 2 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: isToday || dayAppts.isNotEmpty,
              shape: const Border(),
              leading: CircleAvatar(
                backgroundColor: isToday ? const Color(0xFF0EA5E9) : const Color(0xFFF1F5F9),
                child: Text(
                  DateFormat('E').format(day)[0],
                  style: TextStyle(color: isToday ? Colors.white : const Color(0xFF475569), fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(dayTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F172A))),
              subtitle: Text(
                '${dayAppts.length} Scheduled Appointment${dayAppts.length == 1 ? '' : 's'} • ${dayShifts.length} Shift${dayShifts.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              children: [
                if (dayShifts.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: dayShifts.map((sDoc) {
                        final sData = sDoc.data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF0284C7)),
                              const SizedBox(width: 6),
                              Text(
                                "${sData['startTime']} - ${sData['endTime']} (${sData['hospitalName']})",
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (dayAppts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Text('No patient bookings for this day.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  )
                else
                  ...dayAppts.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final patientUid = (data['patientUid'] ?? '').toString();
                    final patientData = patientsMap[patientUid] ?? {};

                    final String patientName = (data['patientName'] ?? patientData['name'] ?? 'Patient').toString();
                    final String time = (data['time'] ?? '09:00 AM').toString();
                    final String status = (data['status'] ?? 'Booked').toString();
                    final String hospital = (data['hospitalName'] ?? data['hospital'] ?? 'Clinic').toString();

                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.person_rounded, color: Color(0xFF0EA5E9), size: 20),
                      title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: Text('$time • $hospital', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'completed'
                              ? const Color(0xFFECFDF5)
                              : status.toLowerCase().contains('cancel')
                                  ? const Color(0xFFFEF2F2)
                                  : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'completed'
                                ? const Color(0xFF047857)
                                : status.toLowerCase().contains('cancel')
                                    ? Colors.redAccent
                                    : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlyView(List<QueryDocumentSnapshot> apptDocs) {
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final firstWeekday = DateTime(_selectedDate.year, _selectedDate.month, 1).weekday;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Days of week header
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Calendar Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: daysInMonth + (firstWeekday - 1),
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox.shrink();
              }

              final dayNum = index - (firstWeekday - 1) + 1;
              final currentDayDate = DateTime(_selectedDate.year, _selectedDate.month, dayNum);

              final count = apptDocs.where((doc) {
                final d = ((doc.data() as Map<String, dynamic>)['date'] ?? '').toString();
                return _isDateMatch(d, currentDayDate);
              }).length;

              final isToday = _isSameDay(DateTime.now(), currentDayDate);
              final isSelected = _isSameDay(_selectedDate, currentDayDate);

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDate = currentDayDate;
                    _currentViewMode = 'Daily';
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0EA5E9)
                        : (isToday ? const Color(0xFFE0F2FE) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0EA5E9)
                          : (isToday ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isSelected
                              ? Colors.white
                              : (isToday ? const Color(0xFF0284C7) : const Color(0xFF0F172A)),
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFF0EA5E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF0EA5E9) : Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
