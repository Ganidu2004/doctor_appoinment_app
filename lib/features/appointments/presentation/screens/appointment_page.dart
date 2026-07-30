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
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
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
    QuerySnapshot schSnap = await FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).collection('schedules').get();
    schedules = schSnap.docs.map((d) => ScheduleModel.fromMap(Map<String, dynamic>.from(d.data() as Map))).toList();

    DateTime today = DateTime.now();
    dateOptions = [];
    fullyBookedMap.clear();
    slotInfoByDate.clear();

    for (int i = 0; i < 14; i++) {
      DateTime date = DateTime(today.year, today.month, today.day).add(Duration(days: i));
      String weekdayFull = DateFormat('EEEE').format(date).toLowerCase();
      String weekdayShort = DateFormat('EEE').format(date).toLowerCase();
      String dateKey = _dateKey(date);

      List<ScheduleModel> daySchedules = schedules.where((s) {
        final d = s.day.toLowerCase();
        return d.contains(weekdayFull) || d.contains(weekdayShort);
      }).where((s) => s.isActive && !s.disabledDates.contains(dateKey)).toList();

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

      QuerySnapshot apptSnap = await FirebaseFirestore.instance.collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('date', isEqualTo: dateKey)
          .get();

      Map<String, int> bookedBySlot = {};
      for (var doc in apptSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final time = (data['time'] ?? '').toString();
        if (time.isEmpty) continue;
        bookedBySlot[time] = (bookedBySlot[time] ?? 0) + 1;
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
  }

  List<String> _generateTimeSlotsForDate(DateTime date) {
    if (schedules.isEmpty) return [];
    String weekdayFull = DateFormat('EEEE').format(date).toLowerCase();
    String weekdayShort = DateFormat('EEE').format(date).toLowerCase();
    String dateKey = _dateKey(date);

    List<ScheduleModel> daySchedules = schedules.where((s) {
      final d = s.day.toLowerCase();
      return d.contains(weekdayFull) || d.contains(weekdayShort);
    }).where((s) => s.isActive && !s.disabledDates.contains(dateKey)).toList();

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
    String dateKey = _dateKey(selectedDate!);

    return schedules.firstWhere(
      (schedule) {
        final dayMatches = schedule.day.toLowerCase().contains(DateFormat('EEEE').format(selectedDate!).toLowerCase()) ||
            schedule.day.toLowerCase().contains(DateFormat('EEE').format(selectedDate!).toLowerCase());
        return dayMatches && schedule.isActive && !schedule.disabledDates.contains(dateKey);
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF0EA5E9)),
              const SizedBox(height: 16),
              Text(
                'Checking slot availability...',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              "Select Appointment Slot",
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              "Step 1 of 2 â€¢ Date & Time",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF0F9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBAE6FD)),
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
                  backgroundColor: const Color(0xFFE0F2FE),
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  "${data['specialization'] ?? 'Specialist'} â€¢ ${data['experience'] ?? '0'} yrs exp",
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
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.payments_rounded, size: 13, color: Color(0xFF047857)),
                      const SizedBox(width: 5),
                      Text(
                        'Fee: ${_formatCurrency(fee)}',
                        style: const TextStyle(
                          color: Color(0xFF047857),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Color(0xFFE11D48), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Consultation Center",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "Hospital / Clinic location",
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F172A)),
          ),
          if (address.isNotEmpty || district.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    [address, district].where((s) => s.isNotEmpty).join(', '),
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 12.5),
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
                const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
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
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Text(
                "Hospital Fee: LKR ${charges.toString()}",
                style: const TextStyle(color: Color(0xFFBE123C), fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    if (dateOptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text('No doctor availability found in the next 2 weeks', style: TextStyle(color: Color(0xFF64748B))),
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
            const Text(
              "Select Date",
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Text(
                monthYear,
                style: const TextStyle(fontSize: 12, color: Color(0xFF0369A1), fontWeight: FontWeight.bold),
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
                        : (isDayFullyBooked ? const Color(0xFFF1F5F9) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDayFullyBooked ? const Color(0xFFE2E8F0) : const Color(0xFFE2E8F0)),
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
                              : (isSelected ? Colors.white70 : const Color(0xFF64748B)),
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
                              : (isSelected ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isDayFullyBooked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'FULL',
                            style: TextStyle(fontSize: 9, color: Color(0xFFB91C1C), fontWeight: FontWeight.bold),
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
    if (selectedDate == null) return const SizedBox.shrink();
    String formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(selectedDate!);
    List<String> slots = _generateTimeSlotsForDate(selectedDate!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Row(
            children: [
              const Icon(Icons.event_available_rounded, color: Color(0xFF0284C7), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("SELECTED DATE", style: TextStyle(fontSize: 10, color: Color(0xFF0369A1), fontWeight: FontWeight.bold)),
                    Text(formattedDate, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.block_rounded, color: Color(0xFFB91C1C), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('All slots are fully booked for this date.', style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.bold, fontSize: 13.5)),
                      SizedBox(height: 2),
                      Text('Please pick another date from the carousel above.', style: TextStyle(color: Color(0xFF7F1D1D), fontSize: 12)),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text('No time slots scheduled for selected date', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F172A)),
            ),
            const SizedBox(width: 6),
            Text(
              '(${slots.length})',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : _statusSurfaceColor(status),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : _statusBorderColor(status),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                                  blurRadius: 12,
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
                      child: Opacity(
                        opacity: isFull ? 0.7 : 1.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white.withValues(alpha: 0.2) : _statusIconBackground(status),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Icon(
                                    isSelected ? Icons.check_rounded : _statusIcon(status),
                                    size: 14,
                                    color: isSelected ? Colors.white : _statusLabelColor(status),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white.withValues(alpha: 0.2) : _statusChipBackground(status),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _statusLabel(status),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : _statusLabelColor(status),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              time,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${info.bookedCount}/${info.capacity} booked',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white70 : const Color(0xFF475569),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: info.capacity > 0 ? (info.bookedCount / info.capacity).clamp(0.0, 1.0) : 0.0,
                                minHeight: 4,
                                backgroundColor: isSelected ? Colors.white24 : const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isSelected ? Colors.white : _statusProgressColor(status),
                                ),
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

  Widget _buildInfoBox() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBAE6FD)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_rounded, color: Color(0xFF0284C7), size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Consultations usually take 20â€“30 minutes. Please arrive 10 minutes prior to your slot time for check-in.",
                style: TextStyle(fontSize: 12, color: Color(0xFF0369A1), height: 1.4, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );

  Widget _buildConfirmBottomBar() {
    final bool canProceed = selectedDate != null && selectedTime != null;
    final fee = _getSelectedScheduleFee();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
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
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                        SizedBox(width: 4),
                        Text('Slot Selected', style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 11)),
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
                    backgroundColor: canProceed ? Colors.transparent : const Color(0xFFE2E8F0),
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        canProceed ? "Proceed to Booking" : "Select Date & Time Slot",
                        style: TextStyle(
                          color: canProceed ? Colors.white : const Color(0xFF94A3B8),
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