import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:appoinment_app/features/doctor/data/models/schedule_model.dart';
import 'appointment_payment_page.dart';

enum SlotStatus { available, almostFull, fullyBooked }

class SelectSlotPage extends StatefulWidget {
  final String doctorId;
  final String patientUid;

  const SelectSlotPage({
    super.key,
    required this.doctorId,
    required this.patientUid,
  });

  @override
  State<SelectSlotPage> createState() => _SelectSlotPageState();
}

class _SlotInfo {
  final int capacity;
  final int bookedCount;
  final bool isFullyBooked;

  _SlotInfo({
    required this.capacity,
    required this.bookedCount,
    required this.isFullyBooked,
  });
}

class _SelectSlotPageState extends State<SelectSlotPage> {
  Map<String, dynamic>? doctorData;
  List<ScheduleModel> schedules = [];
  List<DateTime> dateOptions = [];
  Map<String, bool> fullyBookedMap = {};
  Map<String, Map<String, _SlotInfo>> slotInfoByDate = {};
  Map<String, Map<String, dynamic>> _hospitalsMap = {};

  DateTime? selectedDate;
  String? selectedTime;
  String selectedConsultationType = 'In-Person Clinic Visit';
  bool loading = true;

  StreamSubscription? _schedulesSubscription;

  @override
  void initState() {
    super.initState();
    _initialize();
    _listenToSchedules();
  }

  @override
  void dispose() {
    _schedulesSubscription?.cancel();
    super.dispose();
  }

  void _listenToSchedules() {
    _schedulesSubscription = FirebaseFirestore.instance
        .collection('doctors')
        .doc(widget.doctorId)
        .collection('schedules')
        .snapshots()
        .listen((schSnap) {
      schedules = schSnap.docs
          .map((d) => ScheduleModel.fromMap(Map<String, dynamic>.from(d.data() as Map)))
          .toList();
      _loadSchedulesAndAvailability();
    });
  }

  Future<void> _initialize() async {
    await _fetchDoctorData();
    await _loadHospitals();
    await _loadSchedulesAndAvailability();
    if (mounted) {
      setState(() {
        loading = false;
        if (selectedDate == null && dateOptions.isNotEmpty) {
          selectedDate = dateOptions.firstWhere((date) => !(fullyBookedMap[_dateKey(date)] ?? false), orElse: () => dateOptions.first);
        }
      });
    }
  }

  bool _isScheduleDisabledForDate(ScheduleModel s, DateTime date) {
    if (!s.isActive) return true;
    if (s.disabledDates.isEmpty) return false;

    final k1 = DateFormat('yyyy-MM-dd').format(date);
    final k2 = DateFormat('yyyy-M-d').format(date);
    final k3 = DateFormat('MMMM d, yyyy').format(date);
    final k4 = DateFormat('MMM d, yyyy').format(date);

    for (var disabledStr in s.disabledDates) {
      final trimmed = disabledStr.trim();
      if (trimmed == k1 || trimmed == k2 || trimmed == k3 || trimmed == k4) {
        return true;
      }
      try {
        final parsed = DateTime.tryParse(trimmed);
        if (parsed != null && parsed.year == date.year && parsed.month == date.month && parsed.day == date.day) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  bool _isSameDateStr(String d1Str, String d2Str) {
    if (d1Str.trim() == d2Str.trim()) return true;

    DateTime? parseDate(String s) {
      try {
        return DateFormat("MMMM d, yyyy").parse(s.trim());
      } catch (_) {
        try {
          return DateFormat("yyyy-MM-dd").parse(s.trim());
        } catch (_) {
          try {
            return DateTime.parse(s.trim());
          } catch (_) {
            return null;
          }
        }
      }
    }

    final p1 = parseDate(d1Str);
    final p2 = parseDate(d2Str);

    if (p1 != null && p2 != null) {
      return p1.year == p2.year && p1.month == p2.month && p1.day == p2.day;
    }
    return false;
  }

  Future<void> _fetchDoctorData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).get();
    if (mounted && doc.exists) {
      setState(() {
        doctorData = doc.data() as Map<String, dynamic>?;
      });
    }
  }

  Future<void> _loadHospitals() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('hospital').get();
      if (mounted) {
        setState(() {
          _hospitalsMap = {
            for (var doc in snap.docs) doc.id: doc.data()
          };
        });
      }
    } catch (e) {
      debugPrint("Error loading hospitals: $e");
    }
  }

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<void> _loadSchedulesAndAvailability() async {
    if (schedules.isEmpty) {
      QuerySnapshot schSnap = await FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).collection('schedules').get();
      schedules = schSnap.docs.map((d) => ScheduleModel.fromMap(Map<String, dynamic>.from(d.data() as Map))).toList();
    }

    DateTime today = DateTime.now();
    dateOptions = [];
    fullyBookedMap.clear();
    slotInfoByDate.clear();

    // Fetch all doctor appointments to correctly match dates across all formats
    QuerySnapshot apptSnap = await FirebaseFirestore.instance.collection('appointments')
        .where('doctorId', isEqualTo: widget.doctorId)
        .get();

    for (int i = 0; i < 14; i++) {
      DateTime date = DateTime(today.year, today.month, today.day).add(Duration(days: i));
      String weekdayFull = DateFormat('EEEE').format(date).toLowerCase();
      String weekdayShort = DateFormat('EEE').format(date).toLowerCase();
      String dateKey = _dateKey(date);

      List<ScheduleModel> daySchedules = schedules.where((s) {
        final d = s.day.toLowerCase();
        return (d.contains(weekdayFull) || d.contains(weekdayShort)) && !_isScheduleDisabledForDate(s, date);
      }).toList();

      if (daySchedules.isEmpty) continue;

      Map<String, int> slotCapacities = {};
      Set<String> allSlots = {};

      for (var schedule in daySchedules) {
        List<String> scheduleSlots = _generateTimeSlotsForSchedule(schedule, date);
        if (scheduleSlots.isEmpty) continue;

        int slotCount = scheduleSlots.length;
        int baseCapacity = schedule.maxPatients ~/ slotCount;
        int remainder = schedule.maxPatients % slotCount;

        for (int slotIndex = 0; slotIndex < scheduleSlots.length; slotIndex++) {
          final slot = scheduleSlots[slotIndex];
          int capacity = baseCapacity + (slotIndex < remainder ? 1 : 0);
          slotCapacities[slot] = (slotCapacities[slot] ?? 0) + capacity;
          allSlots.add(slot);
        }
      }

      Map<String, int> bookedBySlot = {};
      for (var doc in apptSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final statusLower = (data['status'] ?? '').toString().toLowerCase();
        if (statusLower.contains('cancel')) continue;

        final apptDate = (data['date'] ?? '').toString();
        if (_isSameDateStr(apptDate, dateKey)) {
          final time = (data['time'] ?? '').toString();
          if (time.isNotEmpty) {
            bookedBySlot[time] = (bookedBySlot[time] ?? 0) + 1;
          }
        }
      }

      bool allSlotsFull = true;
      Map<String, _SlotInfo> slotInfo = {};
      for (var slot in allSlots) {
        final capacity = slotCapacities[slot] ?? 0;
        final booked = bookedBySlot[slot] ?? 0;
        final fully = capacity > 0 && booked >= capacity;
        slotInfo[slot] = _SlotInfo(capacity: capacity, bookedCount: booked, isFullyBooked: fully);
        if (!fully) {
          allSlotsFull = false;
        }
      }

      slotInfoByDate[dateKey] = slotInfo;
      fullyBookedMap[dateKey] = allSlotsFull;
      dateOptions.add(date);
    }

    if (mounted) {
      setState(() {
        if (selectedDate != null && !dateOptions.any((d) => _isSameDateStr(_dateKey(d), _dateKey(selectedDate!)))) {
          selectedDate = dateOptions.isNotEmpty ? dateOptions.first : null;
          selectedTime = null;
        }
      });
    }
  }

  List<String> _generateTimeSlotsForDate(DateTime date) {
    if (schedules.isEmpty) return [];
    String weekdayFull = DateFormat('EEEE').format(date).toLowerCase();
    String weekdayShort = DateFormat('EEE').format(date).toLowerCase();

    List<ScheduleModel> daySchedules = schedules.where((s) {
      final d = s.day.toLowerCase();
      return (d.contains(weekdayFull) || d.contains(weekdayShort)) && !_isScheduleDisabledForDate(s, date);
    }).toList();

    Set<String> slots = {};
    DateFormat ampm = DateFormat('hh:mm a');

    for (var s in daySchedules) {
      slots.addAll(_generateTimeSlotsForSchedule(s, date));
    }

    List<String> sorted = slots.toList()..sort((a, b) => ampm.parse(a).compareTo(ampm.parse(b)));
    return sorted;
  }

  List<String> _generateTimeSlotsForSchedule(ScheduleModel schedule, DateTime date) {
    final start = _parseTimeString(schedule.startTime, date);
    final end = _parseTimeString(schedule.endTime, date);
    if (start == null || end == null) return [];

    Set<String> slots = {};
    DateTime cursor = start;
    while (cursor.isBefore(end)) {
      slots.add(DateFormat('hh:mm a').format(cursor));
      cursor = cursor.add(const Duration(minutes: 20));
    }
    return slots.toList();
  }

  DateTime? _parseTimeString(String timeStr, DateTime date) {
    try {
      final d1 = DateFormat('hh:mm a').parseLoose(timeStr);
      return DateTime(date.year, date.month, date.day, d1.hour, d1.minute);
    } catch (_) {}
    try {
      final d2 = DateFormat('HH:mm').parseLoose(timeStr);
      return DateTime(date.year, date.month, date.day, d2.hour, d2.minute);
    } catch (_) {}
    return null;
  }

  ScheduleModel? _getSelectedSchedule() {
    if (selectedDate == null) return null;

    return schedules.firstWhere(
      (schedule) {
        final dayMatches = schedule.day.toLowerCase().contains(DateFormat('EEEE').format(selectedDate!).toLowerCase()) ||
            schedule.day.toLowerCase().contains(DateFormat('EEE').format(selectedDate!).toLowerCase());
        return dayMatches && !_isScheduleDisabledForDate(schedule, selectedDate!);
      },
      orElse: () => schedules.isNotEmpty ? schedules.first : ScheduleModel(
        id: '',
        day: '',
        startTime: '',
        endTime: '',
        maxPatients: 0,
        consultationFee: 0,
        hospitalId: '',
        hospitalName: '',
        hospitalPhone: '',
        isActive: true,
      ),
    );
  }

  void _navigateToPaymentPage() {
    if (selectedDate == null || selectedTime == null) return;

    final selectedSchedule = _getSelectedSchedule();
    if (selectedSchedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No schedule is available for this date.')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmBookingScreen(
          doctorId: widget.doctorId,
          patientUid: widget.patientUid,
          scheduleId: selectedSchedule.id,
          appointmentDate: DateFormat('MMMM d, yyyy').format(selectedDate!),
          appointmentTime: selectedTime!,
          consultationType: selectedConsultationType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF0EA5E9)),
              const SizedBox(height: 16),
              Text(
                'Checking slot availability...',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              "Select Appointment Slot",
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              "Step 1 of 2 • Date & Time",
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              children: [
                if (doctorData != null) _buildDoctorCard(doctorData!),
                const SizedBox(height: 16),
                _buildHospitalDetails(),
                const SizedBox(height: 16),
                _buildConsultationTypeSelector(),
                _buildDateSelector(),
                const SizedBox(height: 20),
                _buildGeneratedSlotSection(),
                const SizedBox(height: 20),
                _buildInfoBox(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          _buildConfirmBottomBar(),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> data) {
    final fee = _getSelectedScheduleFee();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] : [const Color(0xFFEFF6FF), const Color(0xFFF0F9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0EA5E9), width: 2),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE0F2FE),
                  backgroundImage: data['profileImageUrl'] != null && data['profileImageUrl'].toString().isNotEmpty
                      ? NetworkImage(data['profileImageUrl'])
                      : null,
                  child: data['profileImageUrl'] == null || data['profileImageUrl'].toString().isEmpty
                      ? const Icon(Icons.person_rounded, size: 32, color: Color(0xFF0EA5E9))
                      : null,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF10B981)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dr. ${data['name'] ?? 'Doctor'}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  "${data['specialization'] ?? 'Specialist'} • ${data['experience'] ?? '0'} yrs exp",
                  style: const TextStyle(
                    color: Color(0xFF0284C7),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payments_rounded, size: 13, color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857)),
                      const SizedBox(width: 5),
                      Text(
                        'Fee: ${_formatCurrency(fee)}',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalDetails() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (selectedDate == null) return const SizedBox.shrink();

    final weekdayFull = DateFormat('EEEE').format(selectedDate!).toLowerCase();
    final weekdayShort = DateFormat('EEE').format(selectedDate!).toLowerCase();

    final daySchedule = schedules.firstWhere(
      (s) {
        final d = s.day.toLowerCase();
        return (d.contains(weekdayFull) || d.contains(weekdayShort)) && s.isActive;
      },
      orElse: () => ScheduleModel(
        id: '',
        day: '',
        startTime: '',
        endTime: '',
        maxPatients: 0,
        consultationFee: 0,
        hospitalId: '',
        hospitalName: '',
        hospitalPhone: '',
        isActive: false,
      ),
    );

    if (daySchedule.id.isEmpty) return const SizedBox.shrink();

    Map<String, dynamic>? hospitalData = _hospitalsMap[daySchedule.hospitalId];

    final name = hospitalData?['name'] ?? daySchedule.hospitalName;
    final address = hospitalData?['address'] ?? '';
    final district = hospitalData?['district'] ?? '';
    final contact = hospitalData?['contact'] ?? daySchedule.hospitalPhone;
    final charges = hospitalData?['charges'];

    if (name.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF881337) : const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.local_hospital_rounded, color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Consultation Center",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "Hospital / Clinic location",
                      style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          ),
          Text(
            name,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
          if (address.isNotEmpty || district.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    [address, district].where((s) => s.isNotEmpty).join(', '),
                    style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569), fontSize: 12.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (contact.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  contact,
                  style: const TextStyle(color: Color(0xFF0284C7), fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          if (charges != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF881337) : const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isDark ? const Color(0xFF9F1239) : const Color(0xFFFECDD3)),
              ),
              child: Text(
                "Hospital Fee: LKR ${charges.toString()}",
                style: TextStyle(color: isDark ? const Color(0xFFFDA4AF) : const Color(0xFFBE123C), fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConsultationTypeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.video_camera_front_rounded, color: Color(0xFF0EA5E9), size: 18),
              const SizedBox(width: 8),
              Text(
                'Select Consultation Type',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedConsultationType = 'In-Person Clinic Visit'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    decoration: BoxDecoration(
                      color: selectedConsultationType == 'In-Person Clinic Visit'
                          ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF))
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedConsultationType == 'In-Person Clinic Visit'
                            ? const Color(0xFF2563EB)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: selectedConsultationType == 'In-Person Clinic Visit' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedConsultationType == 'In-Person Clinic Visit'
                                ? (isDark ? const Color(0xFF1D4ED8) : const Color(0xFFDBEAFE))
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_hospital_rounded,
                            color: selectedConsultationType == 'In-Person Clinic Visit'
                                ? (isDark ? Colors.white : const Color(0xFF2563EB))
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'In-Person Clinic',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: selectedConsultationType == 'In-Person Clinic Visit'
                                ? (isDark ? Colors.white : const Color(0xFF1E40AF))
                                : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hospital Visit',
                          style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedConsultationType = 'Online / Live Video Consultation'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    decoration: BoxDecoration(
                      color: selectedConsultationType == 'Online / Live Video Consultation'
                          ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedConsultationType == 'Online / Live Video Consultation'
                            ? const Color(0xFF10B981)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: selectedConsultationType == 'Online / Live Video Consultation' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedConsultationType == 'Online / Live Video Consultation'
                                ? (isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0))
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.videocam_rounded,
                            color: selectedConsultationType == 'Online / Live Video Consultation'
                                ? (isDark ? Colors.white : const Color(0xFF047857))
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Online / Live Video',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: selectedConsultationType == 'Online / Live Video Consultation'
                                ? (isDark ? Colors.white : const Color(0xFF047857))
                                : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Virtual Room',
                          style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (dateOptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Text('No doctor availability found in the next 2 weeks', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        ),
      );
    }
    String monthYear = DateFormat('MMMM yyyy').format(selectedDate ?? dateOptions.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Select Date",
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD)),
              ),
              child: Text(
                monthYear,
                style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 94,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dateOptions.length,
            itemBuilder: (ctx, i) {
              DateTime date = dateOptions[i];
              String dateKey = _dateKey(date);
              bool isSelected = selectedDate != null &&
                  selectedDate!.year == date.year &&
                  selectedDate!.month == date.month &&
                  selectedDate!.day == date.day;
              bool isDayFullyBooked = fullyBookedMap[dateKey] ?? false;

              return GestureDetector(
                onTap: isDayFullyBooked
                    ? null
                    : () => setState(() {
                          selectedDate = date;
                          selectedTime = null;
                        }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  width: 68,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isDayFullyBooked ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)) : (isDark ? const Color(0xFF1E293B) : Colors.white)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date).toUpperCase(),
                        style: TextStyle(
                          color: isDayFullyBooked
                              ? const Color(0xFF94A3B8)
                              : (isSelected ? Colors.white70 : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${date.day}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: isDayFullyBooked
                              ? const Color(0xFF94A3B8)
                              : (isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A))),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isDayFullyBooked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'FULL',
                            style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C), fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        Icon(
                          Icons.circle,
                          size: 6,
                          color: isSelected ? Colors.white : const Color(0xFF10B981),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratedSlotSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (selectedDate == null) return const SizedBox.shrink();
    String formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(selectedDate!);
    List<String> slots = _generateTimeSlotsForDate(selectedDate!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD)),
          ),
          child: Row(
            children: [
              const Icon(Icons.event_available_rounded, color: Color(0xFF0284C7), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("SELECTED DATE", style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1), fontWeight: FontWeight.bold)),
                    Text(formattedDate, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (fullyBookedMap[_dateKey(selectedDate!)] ?? false)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                Icon(Icons.block_rounded, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('All slots are fully booked for this date.', style: TextStyle(color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C), fontWeight: FontWeight.bold, fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text('Please pick another date from the carousel above.', style: TextStyle(color: isDark ? const Color(0xFFFECDD3) : const Color(0xFF7F1D1D), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          )
        else if (slots.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Text('No time slots scheduled for selected date', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
            ),
          )
        else ...[
          _buildSlotSection("Morning Slots", Icons.wb_sunny_rounded, const Color(0xFFF59E0B), slots.where((s) => DateFormat('hh:mm a').parseLoose(s).hour < 12).toList()),
          _buildSlotSection("Afternoon Slots", Icons.wb_twilight_rounded, const Color(0xFF0EA5E9), slots.where((s) { final h = DateFormat('hh:mm a').parseLoose(s).hour; return h >= 12 && h < 17; }).toList()),
          _buildSlotSection("Evening Slots", Icons.nights_stay_rounded, const Color(0xFF6366F1), slots.where((s) => DateFormat('hh:mm a').parseLoose(s).hour >= 17).toList()),
        ],
      ],
    );
  }

  Widget _buildSlotSection(String title, IconData icon, Color iconColor, List<String> slots) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (slots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            const SizedBox(width: 6),
            Text(
              '(${slots.length})',
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final crossAxisCount = availableWidth > 600 ? 3 : 2;
            final spacing = 10.0;
            final totalSpacing = spacing * (crossAxisCount - 1);
            final cardWidth = (availableWidth - totalSpacing) / crossAxisCount;

            return Wrap(
              spacing: spacing,
              runSpacing: 10,
              children: slots.map((time) {
                final dateKey = _dateKey(selectedDate!);
                final info = slotInfoByDate[dateKey]?[time] ?? _SlotInfo(capacity: 0, bookedCount: 0, isFullyBooked: false);
                final isSelected = selectedTime == time;
                final isFull = info.isFullyBooked;
                final status = _getSlotStatus(info);

                return SizedBox(
                  width: cardWidth,
                  child: GestureDetector(
                    onTap: isFull ? null : () => setState(() => selectedTime = time),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : (isDark ? const Color(0xFF1E293B) : _statusSurfaceColor(status)),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? const Color(0xFF334155) : _statusBorderColor(status)),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Opacity(
                        opacity: isFull ? 0.6 : 1.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status chip row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : (isDark
                                            ? _statusIconBackground(status).withValues(alpha: 0.2)
                                            : _statusIconBackground(status)),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Icon(
                                    isSelected ? Icons.check_rounded : _statusIcon(status),
                                    size: 13,
                                    color: isSelected ? Colors.white : _statusLabelColor(status),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : (isDark
                                            ? _statusChipBackground(status).withValues(alpha: 0.25)
                                            : _statusChipBackground(status)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _statusLabel(status),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : _statusLabelColor(status),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Large time display
                            Text(
                              time,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: info.capacity > 0
                                    ? (info.bookedCount / info.capacity).clamp(0.0, 1.0)
                                    : 0.0,
                                minHeight: 5,
                                backgroundColor: isSelected
                                    ? Colors.white24
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isSelected ? Colors.white : _statusProgressColor(status),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Booked count + remaining
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${info.bookedCount}/${info.capacity}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white70
                                        : (isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF475569)),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (info.capacity > 0 && !isFull)
                                  Text(
                                    '${info.capacity - info.bookedCount} left',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white70
                                          : _statusProgressColor(status),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
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
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return 'LKR ${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    )}';
  }

  double _getSelectedScheduleFee() {
    if (selectedDate == null) return 0;
    final matchingSchedules = schedules.where((schedule) {
      final dayMatches = schedule.day.toLowerCase().contains(DateFormat('EEEE').format(selectedDate!).toLowerCase()) ||
          schedule.day.toLowerCase().contains(DateFormat('EEE').format(selectedDate!).toLowerCase());
      return dayMatches && schedule.isActive;
    }).toList();

    if (matchingSchedules.isEmpty) return 0;
    return matchingSchedules.first.consultationFee ?? 0.0;
  }

  Widget _buildInfoBox() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_rounded, color: Color(0xFF0284C7), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Consultations usually take 20-30 minutes. Please arrive 10 minutes prior to your slot time for check-in.",
              style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1), height: 1.4, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmBottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool canProceed = selectedDate != null && selectedTime != null;
    final fee = _getSelectedScheduleFee();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canProceed) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateFormat('EEE, MMM d').format(selectedDate!)} at $selectedTime',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Consultation Fee: ${_formatCurrency(fee)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                        const SizedBox(width: 4),
                        Text('Slot Selected', style: TextStyle(color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  gradient: canProceed
                      ? const LinearGradient(
                          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: canProceed
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: ElevatedButton(
                  onPressed: canProceed ? _navigateToPaymentPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canProceed ? Colors.transparent : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        canProceed ? "Proceed to Booking" : "Select Date & Time Slot",
                        style: TextStyle(
                          color: canProceed ? Colors.white : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (canProceed) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SlotStatus _getSlotStatus(_SlotInfo info) {
    if (info.capacity <= 0 || info.isFullyBooked) return SlotStatus.fullyBooked;
    final ratio = info.bookedCount / info.capacity;
    if (ratio >= 0.75 || info.capacity - info.bookedCount <= 1) {
      return SlotStatus.almostFull;
    }
    return SlotStatus.available;
  }

  Color _statusSurfaceColor(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return const Color(0xFFF4FFF8);
      case SlotStatus.almostFull:
        return const Color(0xFFFFF8ED);
      case SlotStatus.fullyBooked:
        return const Color(0xFFFFF5F5);
    }
  }

  Color _statusBorderColor(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return const Color(0xFFC8F0D6);
      case SlotStatus.almostFull:
        return const Color(0xFFFFDDB5);
      case SlotStatus.fullyBooked:
        return const Color(0xFFF8C3C3);
    }
  }

  Color _statusIconBackground(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return const Color(0xFFDFF8E7);
      case SlotStatus.almostFull:
        return const Color(0xFFFFECCD);
      case SlotStatus.fullyBooked:
        return const Color(0xFFFDE2E2);
    }
  }

  Color _statusChipBackground(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return const Color(0xFFE8F9EE);
      case SlotStatus.almostFull:
        return const Color(0xFFFFF2DA);
      case SlotStatus.fullyBooked:
        return const Color(0xFFFCE8E8);
    }
  }

  Color _statusLabelColor(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return const Color(0xFF1F8F4E);
      case SlotStatus.almostFull:
        return const Color(0xFFB26A00);
      case SlotStatus.fullyBooked:
        return const Color(0xFFB42318);
    }
  }

  Color _statusProgressColor(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return const Color(0xFF2DBE60);
      case SlotStatus.almostFull:
        return const Color(0xFFFFA726);
      case SlotStatus.fullyBooked:
        return const Color(0xFFEF5350);
    }
  }

  IconData _statusIcon(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return Icons.check_circle_outline;
      case SlotStatus.almostFull:
        return Icons.access_time_outlined;
      case SlotStatus.fullyBooked:
        return Icons.block_outlined;
    }
  }

  String _statusLabel(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return 'Available';
      case SlotStatus.almostFull:
        return 'Almost Full';
      case SlotStatus.fullyBooked:
        return 'Fully Booked';
    }
  }
}