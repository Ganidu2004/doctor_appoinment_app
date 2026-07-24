// lib/screens/dashboard/doctor/shedul/doctor_shedul.dart

import 'package:appoinment_app/screens/dashboard/doctor/modles/shedul.dart';
import 'package:appoinment_app/services/notification_services.dart';
import 'package:appoinment_app/services/schedule_cancellation_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MySchedulePage extends StatefulWidget {
  const MySchedulePage({super.key});

  @override
  State<MySchedulePage> createState() => _MySchedulePageState();
}

class _MySchedulePageState extends State<MySchedulePage> {
  final List<String> _weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final List<String> _shortWeekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Map<String, List<ScheduleModel>> _doctorSchedules = {};
  List<Map<String, dynamic>> _doctorHospitals = [];
  bool _isFetching = true;
  String _selectedDayTab = 'Monday';
  String? _activeDayForForm;
  ScheduleModel? _editingSlot;
  Map<String, dynamic>? _selectedHospital;
  String _startTime = "Select Start Time";
  String _endTime = "Select End Time";
  int _maxPatients = 15;
  double _consultationFee = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // Fetch the doctor's profile to get their selected hospitals
        final doctorDoc = await FirebaseFirestore.instance.collection('doctors').doc(uid).get();
        final List<String> profileHospitalIds = [];
        final List<String> profileHospitalNames = [];
        if (doctorDoc.exists && doctorDoc.data() != null) {
          final data = doctorDoc.data()!;
          if (data['hospitalsList'] != null && data['hospitalsList'] is List) {
            for (var item in data['hospitalsList']) {
              if (item is Map) {
                final id = item['hospitalId']?.toString() ?? '';
                final name = item['hospitalName']?.toString() ?? '';
                if (id.isNotEmpty) profileHospitalIds.add(id);
                if (name.isNotEmpty) profileHospitalNames.add(name.toLowerCase());
              }
            }
          }
        }

        // Fetch hospitals from the admin-managed 'hospital' collection
        final hospitalSnapshot = await FirebaseFirestore.instance.collection('hospital').get();
        final seenIds = <String>{};
        final seenNames = <String>{};
        List<Map<String, dynamic>> loadedHospitals = [];

        for (var doc in hospitalSnapshot.docs) {
          final data = doc.data();
          final name = (data['name'] ?? 'Unknown Hospital').trim();
          final id = doc.id;

          // Check if this hospital was selected in the doctor's profile
          final isSelectedInProfile = profileHospitalIds.contains(id) ||
              profileHospitalNames.contains(name.toLowerCase());

          if (isSelectedInProfile && seenIds.add(id)) {
            if (seenNames.add(name.toLowerCase())) {
              loadedHospitals.add({
                'id': id,
                'hospitalName': name,
                'address': data['address'] ?? '',
                'district': data['district'] ?? '',
                'hospitalPhone': data['contact'] ?? '',
                'charges': data['charges'] is num ? (data['charges'] as num).toDouble() : 0.0,
              });
            }
          }
        }

        final snapshot = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(uid)
            .collection('schedules')
            .get();

        Map<String, List<ScheduleModel>> loadedSchedules = {
          for (var day in _weekDays) day: []
        };

        for (var doc in snapshot.docs) {
          final schedule = ScheduleModel.fromMap(doc.data());
          if (loadedSchedules.containsKey(schedule.day)) {
            loadedSchedules[schedule.day]!.add(schedule);
          }
        }

        if (mounted) {
          setState(() {
            _doctorHospitals = loadedHospitals;
            _doctorSchedules = loadedSchedules;

            if (_doctorHospitals.isNotEmpty) {
              _selectedHospital = _doctorHospitals.first;
            } else {
              _selectedHospital = null;
            }

            _isFetching = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading initial data: $e");
      if (mounted) setState(() => _isFetching = false);
    }
  }

  void _initInlineForm(String day, ScheduleModel? slot) {
    setState(() {
      _activeDayForForm = day;
      _editingSlot = slot;

      if (slot != null) {
        _selectedHospital = _doctorHospitals.firstWhere(
          (h) => h['id'] == slot.hospitalId,
          orElse: () => _doctorHospitals.isNotEmpty
              ? _doctorHospitals.first
              : {
                  'id': slot.hospitalId,
                  'hospitalName': slot.hospitalName,
                  'hospitalPhone': slot.hospitalPhone,
                },
        );
      } else {
        _selectedHospital = _doctorHospitals.isNotEmpty ? _doctorHospitals.first : null;
      }

      _startTime = slot?.startTime ?? "Select Start Time";
      _endTime = slot?.endTime ?? "Select End Time";
      _maxPatients = slot?.maxPatients ?? 15;
      _consultationFee = slot?.consultationFee ?? 0;
    });
  }

  void _closeInlineForm() {
    setState(() {
      _activeDayForForm = null;
      _editingSlot = null;
      _selectedHospital = _doctorHospitals.isNotEmpty ? _doctorHospitals.first : null;
      _startTime = "Select Start Time";
      _endTime = "Select End Time";
      _maxPatients = 15;
      _consultationFee = 0;
    });
  }

  void _applyShiftPreset(String startTime, String endTime, int capacity, double fee) {
    setState(() {
      _startTime = startTime;
      _endTime = endTime;
      _maxPatients = capacity;
      _consultationFee = fee;
    });
  }

  Future<void> _saveSlot(String day) async {
    if (_selectedHospital == null || _startTime.contains("Select") || _endTime.contains("Select")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a hospital and valid time slot!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isFetching = true);

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      final firestore = FirebaseFirestore.instance.collection('doctors').doc(uid).collection('schedules');

      DocumentReference docRef = _editingSlot != null ? firestore.doc(_editingSlot!.id) : firestore.doc();

      ScheduleModel newSlot = ScheduleModel(
        id: docRef.id,
        day: day,
        startTime: _startTime,
        endTime: _endTime,
        maxPatients: _maxPatients,
        consultationFee: _consultationFee,
        hospitalId: _selectedHospital!['id'] ?? '',
        hospitalName: _selectedHospital!['hospitalName'] ?? '',
        hospitalPhone: _selectedHospital!['hospitalPhone'] ?? '',
        isActive: _editingSlot?.isActive ?? true,
      );

      await docRef.set(newSlot.toMap());

      try {
        await NotificationService().showNotification(
          id: 201,
          title: _editingSlot != null ? 'Schedule Updated' : 'Schedule Created',
          body: _editingSlot != null
              ? 'The schedule slot was updated successfully.'
              : 'The schedule slot was created successfully.',
        );
      } catch (err) {
        debugPrint('Notification error: $err');
      }

      _closeInlineForm();
      _loadInitialData();
    } catch (e) {
      debugPrint("Error saving slot: $e");
      if (mounted) setState(() => _isFetching = false);
    }
  }



  Future<String?> _promptCancellationReason(
    BuildContext context,
    ScheduleModel slot,
    int affectedCount,
  ) async {
    final TextEditingController reasonController = TextEditingController(
      text: 'Physician unavailable on ${slot.day} (${slot.startTime} - ${slot.endTime}).',
    );

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_note_rounded, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Cancellation Reason', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This shift has $affectedCount active booking(s). Please provide a reason that will be shown to affected patients on their cancellation invoice.',
                style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Reason for Patients',
                  hintText: 'e.g. Emergency leave, Conference duty...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0EA5E9)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final text = reasonController.text.trim();
                Navigator.pop(ctx, text.isNotEmpty ? text : 'Doctor schedule set to Off.');
              },
              child: const Text('Confirm & Notify', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleSlotStatus(ScheduleModel slot) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      final newStatus = !slot.isActive;

      // If turning off an active slot, check for affected appointments
      if (!newStatus) {
        final cancellationService = ScheduleCancellationService();
        final affected = await cancellationService.getAffectedAppointments(
          doctorId: uid,
          day: slot.day,
          startTime: slot.startTime,
          endTime: slot.endTime,
        );

        if (affected.isNotEmpty) {
          if (!mounted) return;
          final customReason = await _promptCancellationReason(context, slot, affected.length);
          if (customReason == null) return; // Doctor cancelled prompt

          setState(() => _isFetching = true);

          final count = await cancellationService.processScheduleCancellation(
            doctorId: uid,
            day: slot.day,
            actionType: 'Pending Patient Choice',
            affectedAppointments: affected,
            reason: customReason,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Schedule set to Off. Generated $count cancellation invoice(s) for affected patients.'),
                backgroundColor: Colors.orange.shade800,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .collection('schedules')
          .doc(slot.id)
          .update({'isActive': newStatus});

      try {
        await NotificationService().showNotification(
          id: 202,
          title: 'Schedule Status Updated',
          body: 'The schedule slot status has been updated successfully.',
        );
      } catch (err) {
        debugPrint('Notification error: $err');
      }

      _loadInitialData();
    } catch (e) {
      debugPrint("Error toggling slot: $e");
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _deleteSlot(ScheduleModel slot) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      final cancellationService = ScheduleCancellationService();
      final affected = await cancellationService.getAffectedAppointments(
        doctorId: uid,
        day: slot.day,
        startTime: slot.startTime,
        endTime: slot.endTime,
      );

      if (affected.isNotEmpty) {
        if (!mounted) return;
        final customReason = await _promptCancellationReason(context, slot, affected.length);
        if (customReason == null) return;

        setState(() => _isFetching = true);

        final count = await cancellationService.processScheduleCancellation(
          doctorId: uid,
          day: slot.day,
          actionType: 'Pending Patient Choice',
          affectedAppointments: affected,
          reason: customReason,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Schedule deleted. Generated $count cancellation invoice(s) for affected patients.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() => _isFetching = true);
      }

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .collection('schedules')
          .doc(slot.id)
          .delete();

      _loadInitialData();
    } catch (e) {
      debugPrint("Error deleting slot: $e");
      if (mounted) setState(() => _isFetching = false);
    }
  }

  int get _totalActiveSlots {
    int total = 0;
    _doctorSchedules.forEach((_, list) {
      total += list.where((s) => s.isActive).length;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0EA5E9);

    if (_isFetching) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Working Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: primaryColor),
            onPressed: () {
              setState(() => _isFetching = true);
              _loadInitialData();
            },
            tooltip: 'Refresh Schedules',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 Header Summary Hero Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Schedule Manager',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_totalActiveSlots Active Working Shifts Configured',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 📅 Day Selector Pill Carousel
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _weekDays.length,
                itemBuilder: (context, index) {
                  final day = _weekDays[index];
                  final shortDay = _shortWeekDays[index];
                  final isSelected = _selectedDayTab == day;
                  final slotCount = _doctorSchedules[day]?.length ?? 0;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDayTab = day;
                      });
                    },
                    child: Container(
                      width: 66,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? primaryColor : Colors.grey.shade200,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            shortDay,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$slotCount slots',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ✍️ Configure / Edit Form (if active)
            if (_activeDayForForm != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: primaryColor, width: 2),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit_calendar_rounded, color: primaryColor, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _editingSlot == null ? "New Shift: $_activeDayForForm" : "Edit Shift: $_activeDayForForm",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.grey),
                              onPressed: _closeInlineForm,
                            )
                          ],
                        ),
                        const Divider(height: 24),

                        // ⚡ Quick Shift Presets
                        const Text(
                          "Quick Shift Presets",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ActionChip(
                                avatar: const Icon(Icons.wb_sunny_outlined, size: 16, color: Colors.orange),
                                label: const Text('Morning OPD', style: TextStyle(fontSize: 12)),
                                backgroundColor: Colors.orange.withValues(alpha: 0.08),
                                onPressed: () => _applyShiftPreset("08:00 AM", "12:00 PM", 20, 2500),
                              ),
                              const SizedBox(width: 8),
                              ActionChip(
                                avatar: const Icon(Icons.nights_stay_outlined, size: 16, color: Colors.indigo),
                                label: const Text('Evening Clinic', style: TextStyle(fontSize: 12)),
                                backgroundColor: Colors.indigo.withValues(alpha: 0.08),
                                onPressed: () => _applyShiftPreset("04:00 PM", "08:00 PM", 15, 3000),
                              ),
                              const SizedBox(width: 8),
                              ActionChip(
                                avatar: const Icon(Icons.local_hospital_outlined, size: 16, color: primaryColor),
                                label: const Text('Weekend Special', style: TextStyle(fontSize: 12)),
                                backgroundColor: primaryColor.withValues(alpha: 0.08),
                                onPressed: () => _applyShiftPreset("09:00 AM", "01:00 PM", 10, 3500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 🏥 Hospital Selection
                        const Text(
                          "Hospital / Clinic",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        _doctorHospitals.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                                ),
                                child: const Text(
                                  "⚠️ No hospitals found in your doctor profile. Contact admin.",
                                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey.shade300),
                                  color: const Color(0xFFF8FAFC),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<Map<String, dynamic>>(
                                    value: _doctorHospitals.any((h) => h['id'] == _selectedHospital?['id'])
                                        ? _selectedHospital
                                        : null,
                                    isExpanded: true,
                                    hint: const Text("Select Hospital / Clinic"),
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
                                    items: _doctorHospitals.map((hospital) {
                                      final district = hospital['district'] ?? '';
                                      final displayName = district.isNotEmpty
                                          ? "${hospital['hospitalName']} — $district"
                                          : hospital['hospitalName'] ?? 'Unknown Hospital';
                                      return DropdownMenuItem<Map<String, dynamic>>(
                                        value: hospital,
                                        child: Row(
                                          children: [
                                            const Icon(Icons.local_hospital_rounded, color: primaryColor, size: 20),
                                            const SizedBox(width: 10),
                                            Expanded(child: Text(displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedHospital = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                        const SizedBox(height: 16),

                        // ⏰ Time Selectors
                        const Text(
                          "Working Hours",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                  if (picked != null) setState(() => _startTime = picked.format(context));
                                },
                                icon: const Icon(Icons.access_time_rounded, color: primaryColor, size: 18),
                                label: Text(_startTime, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                  if (picked != null) setState(() => _endTime = picked.format(context));
                                },
                                icon: const Icon(Icons.access_time_filled_rounded, color: primaryColor, size: 18),
                                label: Text(_endTime, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 💰 Consultation Fee & Capacity
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Consultation Fee", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    initialValue: _consultationFee == 0 ? '' : _consultationFee.toStringAsFixed(0),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      prefixText: 'LKR ',
                                      hintText: '2500',
                                    ),
                                    onChanged: (value) {
                                      final parsed = double.tryParse(value) ?? 0;
                                      setState(() => _consultationFee = parsed);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Max Patients", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300),
                                      color: const Color(0xFFF8FAFC),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          onPressed: () => setState(() => _maxPatients > 1 ? _maxPatients-- : null),
                                          icon: const Icon(Icons.remove_circle_outline, color: primaryColor, size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        Text('$_maxPatients', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        IconButton(
                                          onPressed: () => setState(() => _maxPatients++),
                                          icon: const Icon(Icons.add_circle_outline, color: primaryColor, size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _closeInlineForm,
                              child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              onPressed: _doctorHospitals.isEmpty ? null : () => _saveSlot(_activeDayForForm!),
                              icon: const Icon(Icons.check_circle_rounded, size: 18),
                              label: Text(
                                _editingSlot == null ? "Save Shift" : "Update Shift",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 📋 Schedule Slot Cards for Selected Day
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shifts for $_selectedDayTab',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                          foregroundColor: primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () => _initInlineForm(_selectedDayTab, null),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Shift', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Builder(builder: (context) {
                    List<ScheduleModel> slots = _doctorSchedules[_selectedDayTab] ?? [];

                    if (slots.isEmpty) {
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'No schedules added for $_selectedDayTab',
                                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap "+ Add Shift" above to configure your hours.',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: slots.length,
                      itemBuilder: (context, slotIndex) {
                        final slot = slots[slotIndex];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: slot.isActive ? primaryColor.withValues(alpha: 0.2) : Colors.grey.shade200,
                            ),
                          ),
                          color: slot.isActive ? Colors.white : Colors.grey.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: slot.isActive ? primaryColor.withValues(alpha: 0.1) : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.local_hospital_rounded,
                                        color: slot.isActive ? primaryColor : Colors.grey.shade600,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            slot.hospitalName,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: slot.isActive ? Colors.black87 : Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade600),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${slot.startTime} - ${slot.endTime}",
                                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: slot.isActive,
                                      activeThumbColor: primaryColor,
                                      activeTrackColor: primaryColor.withValues(alpha: 0.4),
                                      onChanged: (value) => _toggleSlotStatus(slot),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "Max: ${slot.maxPatients} Patients",
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "LKR ${(slot.consultationFee ?? 0.0).toStringAsFixed(0)}",
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.orangeAccent),
                                          onPressed: () => _initInlineForm(_selectedDayTab, slot),
                                          tooltip: 'Edit Shift',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                          onPressed: () => _deleteSlot(slot),
                                          tooltip: 'Delete Shift',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}