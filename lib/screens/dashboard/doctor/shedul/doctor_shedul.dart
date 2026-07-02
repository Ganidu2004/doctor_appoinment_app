// lib/screens/dashboard/doctor/shedul/doctor_shedul.dart

import 'package:appoinment_app/screens/dashboard/doctor/modles/shedul.dart';
import 'package:appoinment_app/screens/dashboard/doctor/modles/user_profile.dart';
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
  
  Map<String, List<ScheduleModel>> _doctorSchedules = {};
  List<Map<String, dynamic>> _doctorHospitals = []; 
  bool _isFetching = true;
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
        final doctorDoc = await FirebaseFirestore.instance.collection('doctors').doc(uid).get();
        
        List<Map<String, dynamic>> loadedHospitals = [];
        if (doctorDoc.exists && doctorDoc.data() != null) {
          final doctorModel = DoctorModel.fromMap(doctorDoc.data()!);
          loadedHospitals = doctorModel.hospitalsList;
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
          (h) => h['hospitalName'] == slot.hospitalName,
          orElse: () => _doctorHospitals.isNotEmpty 
              ? _doctorHospitals.first 
              : {
                  'hospitalName': slot.hospitalName, 
                  'hospitalPhone': slot.hospitalPhone,
                  'hospitalAddresses': []
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

  Future<void> _saveSlot(String day) async {
    if (_selectedHospital == null || _startTime.contains("Select") || _endTime.contains("Select")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a hospital and times!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isFetching = true);

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      final firestore = FirebaseFirestore.instance.collection('doctors').doc(uid).collection('schedules');
      
      DocumentReference docRef = _editingSlot != null ? firestore.doc(_editingSlot!.id) : firestore.doc();
      String hospitalContact = _selectedHospital!['hospitalPhone'] ?? '';
      if (hospitalContact.isEmpty && 
          _selectedHospital!['hospitalAddresses'] != null && 
          (_selectedHospital!['hospitalAddresses'] as List).isNotEmpty) {
        hospitalContact = _selectedHospital!['hospitalAddresses'][0].toString();
      }

      ScheduleModel newSlot = ScheduleModel(
        id: docRef.id,
        day: day,
        startTime: _startTime,
        endTime: _endTime,
        maxPatients: _maxPatients,
        consultationFee: _consultationFee,
        hospitalName: _selectedHospital!['hospitalName'] ?? '',
        hospitalPhone: hospitalContact,
        isActive: _editingSlot?.isActive ?? true,
      );

      await docRef.set(newSlot.toMap());
      _closeInlineForm();
      _loadInitialData();
    } catch (e) {
      debugPrint("Error saving slot: $e");
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _toggleSlotStatus(ScheduleModel slot) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .collection('schedules')
          .doc(slot.id)
          .update({'isActive': !slot.isActive});

      _loadInitialData();
    } catch (e) {
      debugPrint("Error toggling slot: $e");
    }
  }

  Future<void> _deleteSlot(ScheduleModel slot) async {
    try {
      setState(() => _isFetching = true);
      String uid = FirebaseAuth.instance.currentUser!.uid;
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

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.blue;

    if (_isFetching) {
      return const Center(child: CircularProgressIndicator(color: primaryColor));
    }

    return Scaffold(
      backgroundColor: Colors.blue[50]!.withValues(alpha: 0.3),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_activeDayForForm != null) ...[
              Card(
                elevation: 4,
                shadowColor: primaryColor.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: primaryColor, width: 1.5),
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
                              const Icon(Icons.edit_calendar, color: primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                _editingSlot == null 
                                    ? "Configure Schedule: $_activeDayForForm" 
                                    : "Edit Schedule: $_activeDayForForm",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: _closeInlineForm,
                          )
                        ],
                      ),
                      const Divider(height: 20),
                      
                      // 💡 Hospital Dropdown Section (Updated with correct fields)
                      _doctorHospitals.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                "⚠️ No hospitals found in your profile! Please add hospitals to your profile first.",
                                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey, width: 1),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<Map<String, dynamic>>(
                                  value: _doctorHospitals.any((h) => h['hospitalName'] == _selectedHospital?['hospitalName']) 
                                      ? _selectedHospital 
                                      : null,
                                  isExpanded: true,
                                  hint: const Text("Select Hospital / Clinic"),
                                  icon: const Icon(Icons.arrow_drop_down, color: primaryColor),
                                  items: _doctorHospitals.map((hospital) {
                                    return DropdownMenuItem<Map<String, dynamic>>(
                                      value: hospital,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.local_hospital, color: primaryColor, size: 20),
                                          const SizedBox(width: 10),
                                          Text(hospital['hospitalName'] ?? 'Unknown Hospital'),
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

                      // Time Selectors
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                if (picked != null) setState(() => _startTime = picked.format(context));
                              },
                              icon: const Icon(Icons.access_time, color: primaryColor, size: 20),
                              label: Text(_startTime, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                              icon: const Icon(Icons.access_time_filled, color: primaryColor, size: 20),
                              label: Text(_endTime, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text('Consultation Fee', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                            ),
                            SizedBox(
                              width: 110,
                              child: TextFormField(
                                initialValue: _consultationFee == 0 ? '' : _consultationFee.toStringAsFixed(0),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  prefixText: 'LKR ',
                                ),
                                onChanged: (value) {
                                  final parsed = double.tryParse(value) ?? 0;
                                  setState(() => _consultationFee = parsed);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Max Patients Counter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Maximum Patients:", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => setState(() => _maxPatients > 1 ? _maxPatients-- : null), 
                                  icon: const Icon(Icons.remove_circle_outline, color: primaryColor)
                                ),
                                Text('$_maxPatients', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                IconButton(
                                  onPressed: () => setState(() => _maxPatients++), 
                                  icon: const Icon(Icons.add_circle_outline, color: primaryColor)
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Actions Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            onPressed: _closeInlineForm,
                            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor, 
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: _doctorHospitals.isEmpty ? null : () => _saveSlot(_activeDayForForm!),
                            child: Text(_editingSlot == null ? "Save Schedule" : "Update Schedule", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _weekDays.length,
              itemBuilder: (context, index) {
                String day = _weekDays[index];
                List<ScheduleModel> slots = _doctorSchedules[day] ?? [];
                bool isFormActiveForThisDay = _activeDayForForm == day;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isFormActiveForThisDay ? primaryColor : Colors.grey.withValues(alpha: 0.15),
                      width: isFormActiveForThisDay ? 1.5 : 1,
                    ),
                  ),
                  color: isFormActiveForThisDay ? Colors.blue[50]!.withValues(alpha: 0.1) : Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _initInlineForm(day, null),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                day,
                                style: TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold, 
                                  color: isFormActiveForThisDay ? primaryColor : Colors.black87
                                ),
                              ),
                              if (slots.isEmpty)
                                const Icon(Icons.add_circle_outline, color: Colors.grey, size: 20),
                            ],
                          ),
                          const Divider(),
                          
                          slots.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text("Tap here to setup schedule for this day.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 13)),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: slots.length,
                                  itemBuilder: (context, slotIndex) {
                                    final slot = slots[slotIndex];
                                    
                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: slot.isActive ? Colors.blue[50]!.withValues(alpha: 0.3) : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: slot.isActive ? primaryColor.withValues(alpha: 0.15) : Colors.transparent),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.local_hospital, size: 16, color: slot.isActive ? primaryColor : Colors.grey),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        slot.hospitalName,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: slot.isActive ? Colors.black87 : Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "${slot.startTime} - ${slot.endTime}  |  Max: ${slot.maxPatients} Patients",
                                                  style: TextStyle(color: slot.isActive ? Colors.grey[700] : Colors.grey, fontSize: 13),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "Fee: Rs.${(slot.consultationFee ?? 0.0).toStringAsFixed((slot.consultationFee ?? 0.0).truncateToDouble() == (slot.consultationFee ?? 0.0) ? 0 : 2)}",
                                                  style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                                                ),
                                                if (slot.hospitalPhone.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "📞 Contact: ${slot.hospitalPhone}",
                                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                                  ),
                                                ]
                                              ],
                                            ),
                                          ),
                                          
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 18, color: Colors.orangeAccent),
                                                onPressed: () => _initInlineForm(day, slot),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                                onPressed: () => _deleteSlot(slot),
                                              ),
                                              Switch(
                                                value: slot.isActive,
                                                activeThumbColor: primaryColor, 
                                                activeTrackColor: primaryColor.withValues(alpha: 0.4), 
                                                onChanged: (value) => _toggleSlotStatus(slot),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}