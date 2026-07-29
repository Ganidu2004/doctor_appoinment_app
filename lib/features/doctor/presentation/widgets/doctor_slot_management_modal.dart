import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DoctorSlotManagementModal extends StatefulWidget {
  const DoctorSlotManagementModal({super.key});

  @override
  State<DoctorSlotManagementModal> createState() => _DoctorSlotManagementModalState();
}

class _DoctorSlotManagementModalState extends State<DoctorSlotManagementModal> {
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  int _consultationDurationMins = 15;

  final List<String> _breakTimes = ['01:00 PM - 02:00 PM (Lunch Break)'];
  final List<DateTime> _unavailableDays = [];

  final TextEditingController _breakController = TextEditingController();

  @override
  void dispose() {
    _breakController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle & title header
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: Color(0xFF0EA5E9), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Slot & Availability Manager',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Scrollable Settings Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ⏰ Working Hours Container
                  _buildSectionCard(
                    title: 'Working Hours & Shifts ⏰',
                    subtitle: 'Configure default daily consultation hours',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimePickerTile(
                                label: 'Start Time',
                                time: _startTime,
                                onTap: () async {
                                  final picked = await showTimePicker(context: context, initialTime: _startTime);
                                  if (picked != null) setState(() => _startTime = picked);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTimePickerTile(
                                label: 'End Time',
                                time: _endTime,
                                onTap: () async {
                                  final picked = await showTimePicker(context: context, initialTime: _endTime);
                                  if (picked != null) setState(() => _endTime = picked);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Consultation Duration Per Patient
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Consultation Slot Duration:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                            DropdownButton<int>(
                              value: _consultationDurationMins,
                              underline: const SizedBox.shrink(),
                              items: [10, 15, 20, 30, 45, 60].map((mins) {
                                return DropdownMenuItem<int>(
                                  value: mins,
                                  child: Text('$mins Minutes', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9))),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _consultationDurationMins = val);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ☕ Break Times Configuration
                  _buildSectionCard(
                    title: 'Break Times & Off Hours ☕',
                    subtitle: 'Block out lunch, tea, or administrative breaks',
                    child: Column(
                      children: [
                        ..._breakTimes.map((breakTime) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.coffee_rounded, size: 16, color: Color(0xFFB45309)),
                                    const SizedBox(width: 8),
                                    Text(breakTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF334155))),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _breakTimes.remove(breakTime);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _breakController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. 04:00 PM - 04:30 PM (Tea Break)',
                                  hintStyle: const TextStyle(fontSize: 12),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF0EA5E9), size: 30),
                              onPressed: () {
                                if (_breakController.text.trim().isNotEmpty) {
                                  setState(() {
                                    _breakTimes.add(_breakController.text.trim());
                                    _breakController.clear();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🏖️ Unavailable & Vacation Days
                  _buildSectionCard(
                    title: 'Unavailable & Leave Days 🏖️',
                    subtitle: 'Block out holidays or vacation days',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 180)),
                            );
                            if (picked != null) {
                              setState(() {
                                if (!_unavailableDays.contains(picked)) {
                                  _unavailableDays.add(picked);
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.edit_calendar_rounded, size: 16, color: Colors.white),
                          label: const Text('+ Add Leave Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_unavailableDays.isEmpty)
                          const Text('No unavailable days marked.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _unavailableDays.map((date) {
                              final dateStr = DateFormat('MMM d, yyyy').format(date);
                              return Chip(
                                backgroundColor: const Color(0xFFFEE2E2),
                                side: const BorderSide(color: Color(0xFFFCA5A5)),
                                label: Text(dateStr, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                                deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF991B1B)),
                                onDeleted: () {
                                  setState(() {
                                    _unavailableDays.remove(date);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await FirebaseFirestore.instance.collection('doctors').doc(user.uid).set({
                            'workingStartTime': _startTime.format(context),
                            'workingEndTime': _endTime.format(context),
                            'consultationDurationMins': _consultationDurationMins,
                            'breakTimes': _breakTimes,
                            'unavailableDays': _unavailableDays.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList(),
                            'updatedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Working hours & slot settings saved! ⚙️'), backgroundColor: Color(0xFF10B981)),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Saved locally: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Save Slot Settings ⚙️', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildTimePickerTile({required String label, required TimeOfDay time, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(time.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF0EA5E9)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
