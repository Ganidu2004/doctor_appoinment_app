import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../doctor/modles/shedul.dart';
import 'appoiment_payment_page.dart';

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

      List<ScheduleModel> daySchedules = schedules.where((s) {
        final d = s.day.toLowerCase();
        return d.contains(weekdayFull) || d.contains(weekdayShort);
      }).where((s) => s.isActive).toList();

      if (daySchedules.isEmpty) continue;

      String dateKey = _dateKey(date);
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

    List<ScheduleModel> daySchedules = schedules.where((s) {
      final d = s.day.toLowerCase();
      return d.contains(weekdayFull) || d.contains(weekdayShort);
    }).where((s) => s.isActive).toList();

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
        return dayMatches && schedule.isActive;
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
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Select Appointment", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  if (doctorData != null) _buildDoctorCard(doctorData!),
                  const SizedBox(height: 20),
                  _buildHospitalDetails(),
                  _buildDateSelector(),
                  const SizedBox(height: 20),
                  _buildGeneratedSlotSection(),
                  const SizedBox(height: 20),
                  _buildInfoBox(),
                ],
              ),
            ),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> data) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: data['profileImageUrl'] != null ? NetworkImage(data['profileImageUrl']) : null,
              child: data['profileImageUrl'] == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 15),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Dr. ${data['name'] ?? 'Doctor'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("${data['specialization'] ?? 'Specialist'} • ${data['experience'] ?? '0'} yrs exp"),
              const SizedBox(height: 4),
              Text(
                'Consultation fee: ${_formatCurrency(_getSelectedScheduleFee())}',
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ]),
          ],
        ),
      );

  Widget _buildHospitalDetails() {
    if (selectedDate == null) return const SizedBox.shrink();
    
    // Find active schedule for selectedDate
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
    
    // Try to get details from loaded hospitals map
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
        color: Colors.red.shade50.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_hospital, color: Colors.red.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Hospital Details",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(height: 12),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          if (address.isNotEmpty || district.isNotEmpty) ...[
            Text(
              [address, district].where((s) => s.isNotEmpty).join(', '),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
          if (contact.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              "📞 Contact: $contact",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
          if (charges != null) ...[
            const SizedBox(height: 4),
            Text(
              "Hospital Charges: LKR ${charges.toString()}",
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    if (dateOptions.isEmpty) {
      return const Text('No availability in the next 2 weeks', style: TextStyle(color: Colors.grey));
    }
    String monthYear = DateFormat('MMMM yyyy').format(selectedDate ?? dateOptions.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Select Date", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(monthYear, style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dateOptions.length,
            itemBuilder: (ctx, i) {
              DateTime date = dateOptions[i];
              String dateKey = _dateKey(date);
              bool isSelected = selectedDate != null && selectedDate!.year == date.year && selectedDate!.month == date.month && selectedDate!.day == date.day;
              bool isDayFullyBooked = fullyBookedMap[dateKey] ?? false;

              return GestureDetector(
                onTap: isDayFullyBooked
                    ? null
                    : () => setState(() { selectedDate = date; selectedTime = null; }),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 60,
                  decoration: BoxDecoration(
                    color: isDayFullyBooked ? Colors.grey.shade200 : (isSelected ? Colors.blue : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(DateFormat('E').format(date).toUpperCase(), style: TextStyle(color: isDayFullyBooked ? Colors.grey : (isSelected ? Colors.white : Colors.grey), fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text("${date.day}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDayFullyBooked ? Colors.grey : (isSelected ? Colors.white : Colors.black))),
                    if (isDayFullyBooked) ...[
                      const SizedBox(height: 6),
                      const Text('FULL', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ]),
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
    String formattedDate = DateFormat('MMMM d, yyyy').format(selectedDate!);
    List<String> slots = _generateTimeSlotsForDate(selectedDate!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("AVAILABILITY FOR", style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                  Text(formattedDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (fullyBookedMap[_dateKey(selectedDate!)] ?? false)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('This day is fully booked.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Please select another date to book an appointment.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        else if (slots.isEmpty)
          const Padding(padding: EdgeInsets.all(12), child: Text('No time slots for selected date', style: TextStyle(color: Colors.grey)))
        else ...[
          _buildSlotSection("MORNING", Icons.wb_sunny_outlined, slots.where((s) => DateFormat('hh:mm a').parseLoose(s).hour < 12).toList()),
          _buildSlotSection("AFTERNOON", Icons.wb_twilight_outlined, slots.where((s) { final h = DateFormat('hh:mm a').parseLoose(s).hour; return h >= 12 && h < 17; }).toList()),
          _buildSlotSection("EVENING", Icons.nights_stay_outlined, slots.where((s) => DateFormat('hh:mm a').parseLoose(s).hour >= 17).toList()),
        ],
      ],
    );
  }

  Widget _buildSlotSection(String title, IconData icon, List<String> slots) {
    if (slots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final crossAxisCount = availableWidth > 720 ? 3 : 2;
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
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1D4ED8)
                            : _statusSurfaceColor(status),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1D4ED8)
                              : _statusBorderColor(status),
                          width: isSelected ? 1.6 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.blue.shade100,
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: Opacity(
                        opacity: isFull ? 0.75 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white.withValues(alpha: 0.16) : _statusIconBackground(status),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _statusIcon(status),
                                    size: 15,
                                    color: isSelected ? Colors.white : _statusLabelColor(status),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white.withValues(alpha: 0.16) : _statusChipBackground(status),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _statusLabel(status),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : _statusLabelColor(status),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              time,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${info.bookedCount}/${info.capacity} booked',
                              style: TextStyle(
                                color: isSelected ? Colors.white70 : Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Max ${info.capacity} patients',
                              style: TextStyle(
                                color: isSelected ? Colors.white70 : Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: info.capacity > 0 ? (info.bookedCount / info.capacity).clamp(0.0, 1.0) : 0.0,
                                minHeight: 6,
                                backgroundColor: isSelected ? Colors.white24 : Colors.grey.shade200,
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
        const SizedBox(height: 20),
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
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.blue.shade700, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Appointments usually take 30–45 minutes. Please arrive 10 minutes early to help everything run smoothly.",
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.4),
              ),
            ),
          ],
        ),
      );

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

  Widget _buildConfirmButton() => SizedBox(
        width: double.infinity, height: 55,
        child: ElevatedButton(
          onPressed: (selectedTime == null || selectedDate == null) ? null : _navigateToPaymentPage,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text("Confirm Appointment", style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      );
}