// lib/screens/dashboard/doctor/shedul/doctor_shedul.dart

import 'package:appoinment_app/features/doctor/data/models/schedule_model.dart';
import 'package:appoinment_app/core/services/notification_services.dart';
import 'package:appoinment_app/core/services/schedule_cancellation_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:appoinment_app/features/doctor/presentation/screens/doctor_calendar_schedule_page.dart';
import 'package:appoinment_app/features/doctor/presentation/widgets/doctor_slot_management_modal.dart';

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
        // Fetch the doctor's profile to get any pre-selected hospital IDs or names
        final doctorDoc = await FirebaseFirestore.instance.collection('doctors').doc(uid).get();
        final Set<String> profileHospitalIds = {};
        final Set<String> profileHospitalNames = {};
        List<Map<String, dynamic>> profileHospitals = [];

        if (doctorDoc.exists && doctorDoc.data() != null) {
          final data = doctorDoc.data()!;
          if (data['hospitalsList'] != null && data['hospitalsList'] is List) {
            for (var item in data['hospitalsList']) {
              if (item is Map) {
                final id = item['hospitalId']?.toString() ?? item['id']?.toString() ?? '';
                final name = item['hospitalName']?.toString() ?? item['name']?.toString() ?? '';
                final district = item['hospitalDistrict']?.toString() ?? item['district']?.toString() ?? '';
                final phone = item['hospitalPhone']?.toString() ?? item['phone']?.toString() ?? item['contact']?.toString() ?? '';

                if (id.isNotEmpty) profileHospitalIds.add(id);
                if (name.isNotEmpty) profileHospitalNames.add(name.trim().toLowerCase());

                if (id.isNotEmpty || name.isNotEmpty) {
                  profileHospitals.add({
                    'id': id.isNotEmpty ? id : name,
                    'hospitalName': name.isNotEmpty ? name : 'Unknown Hospital',
                    'address': item['address']?.toString() ?? '',
                    'district': district,
                    'hospitalPhone': phone,
                    'charges': 0.0,
                    'isAssigned': true,
                  });
                }
              }
            }
          }
        }

        // Fetch hospitals dynamically from the admin-managed 'hospital' collection
        final hospitalSnapshot = await FirebaseFirestore.instance.collection('hospital').get();
        final seenIds = <String>{};
        final seenNames = <String>{};
        List<Map<String, dynamic>> loadedHospitals = [];

        for (var doc in hospitalSnapshot.docs) {
          final data = doc.data();
          final name = (data['name'] ?? 'Unknown Hospital').toString().trim();
          final id = doc.id;

          final isAssigned = profileHospitalIds.contains(id) ||
              profileHospitalNames.contains(name.toLowerCase());

          if (seenIds.add(id)) {
            seenNames.add(name.toLowerCase());
            loadedHospitals.add({
              'id': id,
              'hospitalName': name,
              'address': data['address']?.toString() ?? '',
              'district': data['district']?.toString() ?? '',
              'hospitalPhone': data['contact']?.toString() ?? '',
              'charges': data['charges'] is num ? (data['charges'] as num).toDouble() : 0.0,
              'isAssigned': isAssigned,
            });
          }
        }

        // Merge profile hospitals not found in 'hospital' collection
        for (var pHospital in profileHospitals) {
          final id = pHospital['id']?.toString() ?? '';
          final name = pHospital['hospitalName']?.toString().trim() ?? '';
          if (name.isNotEmpty) {
            final lowerName = name.toLowerCase();
            if (!seenNames.contains(lowerName) && (id.isEmpty || !seenIds.contains(id))) {
              if (id.isNotEmpty) seenIds.add(id);
              seenNames.add(lowerName);
              loadedHospitals.add(pHospital);
            }
          }
        }

        // Sort: Doctor's assigned profile hospitals first, followed by remaining database hospitals alphabetically
        loadedHospitals.sort((a, b) {
          final aAssigned = a['isAssigned'] == true;
          final bAssigned = b['isAssigned'] == true;
          if (aAssigned && !bAssigned) return -1;
          if (!aAssigned && bAssigned) return 1;
          return (a['hospitalName'] as String).toLowerCase().compareTo((b['hospitalName'] as String).toLowerCase());
        });

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
          (h) => h['id'] == slot.hospitalId || (h['hospitalName']?.toString().toLowerCase() == slot.hospitalName.toLowerCase()),
          orElse: () {
            final fallback = {
              'id': slot.hospitalId,
              'hospitalName': slot.hospitalName,
              'hospitalPhone': slot.hospitalPhone,
              'address': '',
              'district': '',
              'charges': 0.0,
              'isAssigned': false,
            };
            _doctorHospitals.add(fallback);
            return fallback;
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

  TimeOfDay _parseTimeOfDay(String timeString) {
    if (timeString.contains("Select") || timeString.trim().isEmpty) {
      return TimeOfDay.now();
    }
    try {
      final clean = timeString.trim();
      final isPm = clean.toUpperCase().contains("PM");
      final isAm = clean.toUpperCase().contains("AM");
      final parts = clean.replaceAll(RegExp(r'[^\d:]'), '').split(':');

      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);

        if (isPm && hour < 12) {
          hour += 12;
        } else if (isAm && hour == 12) {
          hour = 0;
        }

        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      debugPrint("Error parsing TimeOfDay from string '$timeString': $e");
    }
    return TimeOfDay.now();
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

      // Update doctor's profile document hospitalsList in Firestore if this hospital isn't in it yet
      final doctorDocRef = FirebaseFirestore.instance.collection('doctors').doc(uid);
      final doctorDoc = await doctorDocRef.get();

      if (doctorDoc.exists) {
        final data = doctorDoc.data() ?? {};
        List<dynamic> currentHospitalsList = List.from(data['hospitalsList'] ?? []);

        final selectedId = (_selectedHospital!['id'] ?? '').toString();
        final selectedName = (_selectedHospital!['hospitalName'] ?? '').toString().trim().toLowerCase();

        bool alreadyAssigned = currentHospitalsList.any((item) {
          if (item is Map) {
            final id = (item['hospitalId'] ?? item['id'] ?? '').toString();
            final name = (item['hospitalName'] ?? item['name'] ?? '').toString().trim().toLowerCase();
            return (selectedId.isNotEmpty && id == selectedId) || (selectedName.isNotEmpty && name == selectedName);
          }
          return false;
        });

        if (!alreadyAssigned) {
          final newHospitalEntry = {
            'hospitalId': _selectedHospital!['id'] ?? '',
            'hospitalName': _selectedHospital!['hospitalName'] ?? '',
            'hospitalPhone': _selectedHospital!['hospitalPhone'] ?? '',
            'hospitalDistrict': _selectedHospital!['district'] ?? '',
            'hospitalAddresses': [
              if ((_selectedHospital!['address'] ?? '').toString().isNotEmpty)
                _selectedHospital!['address'].toString()
            ],
          };

          await doctorDocRef.update({
            'hospitalsList': FieldValue.arrayUnion([newHospitalEntry]),
          });
        }
      }

      // Update in-memory assigned state instantly
      if (mounted) {
        _selectedHospital!['isAssigned'] = true;
        for (var h in _doctorHospitals) {
          if (h['id'] == _selectedHospital!['id'] || h['hospitalName'] == _selectedHospital!['hospitalName']) {
            h['isAssigned'] = true;
          }
        }
      }

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
      await _loadInitialData();
    } catch (e) {
      debugPrint("Error saving slot: $e");
      if (mounted) setState(() => _isFetching = false);
    }
  }



  DateTime _getUpcomingDateForDay(String dayName) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    const daysMap = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };
    int targetWeekday = daysMap[dayName.trim().toLowerCase()] ?? DateTime.monday;
    int daysAhead = targetWeekday - today.weekday;
    if (daysAhead < 0) {
      daysAhead += 7;
    }
    return today.add(Duration(days: daysAhead));
  }

  Future<String?> _promptDisableOption(
    BuildContext context,
    ScheduleModel slot,
    String upcomingDateDisplay,
  ) async {
    String selectedOption = 'upcoming';

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.toggle_off_rounded, color: Colors.orange, size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Disable Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose how you want to disable this shift (${slot.day}, ${slot.startTime} - ${slot.endTime}):',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () => setDialogState(() => selectedOption = 'upcoming'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedOption == 'upcoming' ? const Color(0xFFF0F9FF) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedOption == 'upcoming' ? const Color(0xFF0EA5E9) : Colors.grey.shade300,
                          width: selectedOption == 'upcoming' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            selectedOption == 'upcoming' ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: selectedOption == 'upcoming' ? const Color(0xFF0EA5E9) : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Disable for Upcoming Week Only', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  'Temporarily disables shift on $upcomingDateDisplay. Patient invoicing will cancel appointments for this date only. Resumes automatically next week.',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => setDialogState(() => selectedOption = 'permanent'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedOption == 'permanent' ? const Color(0xFFFEF2F2) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedOption == 'permanent' ? Colors.redAccent : Colors.grey.shade300,
                          width: selectedOption == 'permanent' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            selectedOption == 'permanent' ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: selectedOption == 'permanent' ? Colors.redAccent : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Disable Permanently', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text(
                                  'Disables this recurring shift indefinitely. Patient invoicing will cancel all current and future booked appointments under this shift.',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                  onPressed: () => Navigator.pop(ctx, selectedOption),
                  child: const Text('Proceed', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
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
      final upcomingDate = _getUpcomingDateForDay(slot.day);
      final upcomingDateKey = DateFormat('yyyy-MM-dd').format(upcomingDate);
      final upcomingDateDisplay = DateFormat('EEEE, MMM d').format(upcomingDate);

      final bool isCurrentlyActiveForUpcoming = slot.isActive && !slot.disabledDates.contains(upcomingDateKey);

      if (isCurrentlyActiveForUpcoming) {
        final option = await _promptDisableOption(context, slot, upcomingDateDisplay);
        if (option == null) return;

        final cancellationService = ScheduleCancellationService();

        if (option == 'upcoming') {
          final affected = await cancellationService.getAffectedAppointments(
            doctorId: uid,
            day: slot.day,
            startTime: slot.startTime,
            endTime: slot.endTime,
            targetDate: upcomingDateKey,
          );

          String? customReason;
          if (affected.isNotEmpty) {
            if (!mounted) return;
            customReason = await _promptCancellationReason(context, slot, affected.length);
            if (customReason == null) return;
          }

          setState(() => _isFetching = true);

          int count = 0;
          if (affected.isNotEmpty) {
            count = await cancellationService.processScheduleCancellation(
              doctorId: uid,
              day: slot.day,
              actionType: 'Pending Patient Choice',
              affectedAppointments: affected,
              reason: customReason ?? 'Doctor schedule set to Off for $upcomingDateDisplay.',
            );
          }

          await FirebaseFirestore.instance
              .collection('doctors')
              .doc(uid)
              .collection('schedules')
              .doc(slot.id)
              .update({
            'disabledDates': FieldValue.arrayUnion([upcomingDateKey]),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Schedule disabled for $upcomingDateDisplay. Generated $count cancellation invoice(s).'),
                backgroundColor: Colors.orange.shade800,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else if (option == 'permanent') {
          final affected = await cancellationService.getAffectedAppointments(
            doctorId: uid,
            day: slot.day,
            startTime: slot.startTime,
            endTime: slot.endTime,
          );

          String? customReason;
          if (affected.isNotEmpty) {
            if (!mounted) return;
            customReason = await _promptCancellationReason(context, slot, affected.length);
            if (customReason == null) return;
          }

          setState(() => _isFetching = true);

          int count = 0;
          if (affected.isNotEmpty) {
            count = await cancellationService.processScheduleCancellation(
              doctorId: uid,
              day: slot.day,
              actionType: 'Pending Patient Choice',
              affectedAppointments: affected,
              reason: customReason ?? 'Doctor schedule permanently set to Off.',
            );
          }

          await FirebaseFirestore.instance
              .collection('doctors')
              .doc(uid)
              .collection('schedules')
              .doc(slot.id)
              .update({
            'isActive': false,
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Schedule permanently set to Off. Generated $count cancellation invoice(s).'),
                backgroundColor: Colors.orange.shade800,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        setState(() => _isFetching = true);

        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(uid)
            .collection('schedules')
            .doc(slot.id)
            .update({
          'isActive': true,
          'disabledDates': FieldValue.arrayRemove([upcomingDateKey]),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Schedule re-enabled for ${slot.day}.'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

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
            icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF0EA5E9)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DoctorCalendarSchedulePage()),
              );
            },
            tooltip: 'Calendar & Schedule View',
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFFF97316)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const DoctorSlotManagementModal(),
              );
            },
            tooltip: 'Slot & Availability Manager',
          ),
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
            // Header Summary Hero Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Schedule Manager',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_totalActiveSlots Active Working Shifts Configured',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Day Selector Pill Carousel
            Container(
              height: 76,
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 68,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
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
                            shortDay,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$slotCount slots',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
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

            // Configure / Edit Form (if active)
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

                        // Quick Shift Presets
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

                        // Hospital Selection
                        const Text(
                          "Hospital / Clinic",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        _doctorHospitals.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "No hospitals available in database. Contact admin.",
                                        style: TextStyle(color: Colors.black87, fontSize: 13),
                                      ),
                                    ),
                                  ],
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
                                    value: _doctorHospitals.firstWhere(
                                      (h) => h['id'] == _selectedHospital?['id'] || (h['hospitalName']?.toString().toLowerCase() == _selectedHospital?['hospitalName']?.toString().toLowerCase()),
                                      orElse: () => _doctorHospitals.first,
                                    ),
                                    isExpanded: true,
                                    hint: const Text("Select Hospital / Clinic"),
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
                                    items: _doctorHospitals.map((hospital) {
                                      final district = (hospital['district'] ?? '').toString();
                                      final isAssigned = hospital['isAssigned'] == true;
                                      final name = hospital['hospitalName'] ?? 'Unknown Hospital';
                                      
                                      String displayName = name;
                                      if (district.isNotEmpty) {
                                        displayName += " — $district";
                                      }

                                      return DropdownMenuItem<Map<String, dynamic>>(
                                        value: hospital,
                                        child: Row(
                                          children: [
                                            const Icon(Icons.local_hospital_rounded, color: primaryColor, size: 20),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                displayName,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                            if (isAssigned) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: primaryColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'Assigned',
                                                  style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
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

                        // ⏲ Time Selectors
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
                                  TimeOfDay initial = _parseTimeOfDay(_startTime);
                                  TimeOfDay? picked = await showTimePicker(context: context, initialTime: initial);
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
                                  TimeOfDay initial = _parseTimeOfDay(_endTime);
                                  TimeOfDay? picked = await showTimePicker(context: context, initialTime: initial);
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

                        // Consultation Fee & Capacity
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

            // Schedule Slot Cards for Selected Day
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
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onPressed: () => _initInlineForm(_selectedDayTab, null),
                          icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                          label: const Text('Add Shift', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Builder(builder: (context) {
                    List<ScheduleModel> slots = _doctorSchedules[_selectedDayTab] ?? [];

                    if (slots.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF0F9FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.event_busy_rounded, size: 36, color: Color(0xFF0EA5E9)),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No schedules added for $_selectedDayTab',
                                style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap "+ Add Shift" above to configure working hours.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                              ),
                            ],
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
                        final upcomingDate = _getUpcomingDateForDay(slot.day);
                        final upcomingDateKey = DateFormat('yyyy-MM-dd').format(upcomingDate);
                        final upcomingDateDisplay = DateFormat('MMM d').format(upcomingDate);
                        final bool isTemporarilyDisabled = slot.disabledDates.contains(upcomingDateKey);
                        final bool isSlotActiveForUpcoming = slot.isActive && !isTemporarilyDisabled;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: isSlotActiveForUpcoming ? Colors.white : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Stack(
                              children: [
                                // Left Status Accent Bar Indicator
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 5,
                                    color: isSlotActiveForUpcoming
                                        ? const Color(0xFF10B981)
                                        : (isTemporarilyDisabled ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isSlotActiveForUpcoming ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              Icons.local_hospital_rounded,
                                              color: isSlotActiveForUpcoming ? const Color(0xFF0284C7) : const Color(0xFF64748B),
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
                                                    fontSize: 15.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: isSlotActiveForUpcoming ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF0F9FF),
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: const Color(0xFFBAE6FD)),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF0284C7)),
                                                          const SizedBox(width: 5),
                                                          Text(
                                                            "${slot.startTime} - ${slot.endTime}",
                                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (!slot.isActive) ...[
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                                        ),
                                                        child: const Text(
                                                          'Permanently Off',
                                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                                        ),
                                                      ),
                                                    ] else if (isTemporarilyDisabled) ...[
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.amber.withValues(alpha: 0.12),
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                                                        ),
                                                        child: Text(
                                                          'Off on $upcomingDateDisplay',
                                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Switch(
                                            value: isSlotActiveForUpcoming,
                                            activeThumbColor: const Color(0xFF0EA5E9),
                                            activeTrackColor: const Color(0xFFBAE6FD),
                                            onChanged: (value) => _toggleSlotStatus(slot),
                                          ),
                                        ],
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                                      ),
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
                                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFECFDF5),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                                ),
                                                child: Text(
                                                  "LKR ${(slot.consultationFee ?? 0.0).toStringAsFixed(0)}",
                                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () => _initInlineForm(_selectedDayTab, slot),
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFFFBEB),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                                  ),
                                                  child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFB45309)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: () => _deleteSlot(slot),
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFEF2F2),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: const Color(0xFFFECACA)),
                                                  ),
                                                  child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
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