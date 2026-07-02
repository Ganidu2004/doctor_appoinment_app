import 'package:appoinment_app/screens/dashboard/appoiment/appoiment_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DoctorDetailPage extends StatefulWidget {
  final String doctorId;
  const DoctorDetailPage({super.key, required this.doctorId});

  @override
  State<DoctorDetailPage> createState() => _DoctorDetailPageState();
}

class _DoctorDetailPageState extends State<DoctorDetailPage> {
  String hName = "Selecting...";
  String hAddress = "Please select a date";

  late Future<DocumentSnapshot> _doctorFuture;
  late Future<QuerySnapshot> _scheduleFuture;

  @override
  void initState() {
    super.initState();
    _doctorFuture = FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).get();
    _scheduleFuture = FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).collection('schedules').get();
  }

  void updateLocation(String name, String address) {
    if (mounted) {
      setState(() {
        hName = name;
        hAddress = address;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<DocumentSnapshot>(
        future: _doctorFuture,
        builder: (context, doctorSnapshot) {
          if (!doctorSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = doctorSnapshot.data!.data() as Map<String, dynamic>;
          final List hospitalsList = data['hospitalsList'] ?? [];

          return FutureBuilder<QuerySnapshot>(
            future: _scheduleFuture,
            builder: (context, scheduleSnapshot) {
              List<Map<String, dynamic>> scheduleList = [];
              if (scheduleSnapshot.hasData) {
                scheduleList = scheduleSnapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
              }

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Image.network(data['profileImageUrl'] ?? '', fit: BoxFit.cover),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dr. ${data['name'] ?? ''}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text(data['specialization'] ?? '', style: const TextStyle(color: Colors.blue, fontSize: 16)),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatBox('${data['experience'] ?? 0}+ Yrs', 'EXPERIENCE'),
                              _buildStatBox('${data['patients'] ?? 0}+', 'PATIENTS'),
                              _buildStatBox('${data['rating'] ?? 0.0}', 'RATING'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text("About Doctor", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(data['aboutMe'] ?? "", style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 20),
                          ListTile(
                            leading: const Icon(Icons.location_on, color: Colors.blue),
                            title: Text(hName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(hAddress),
                            tileColor: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          const SizedBox(height: 24),
                          const Text("Next Availability", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ScheduleSection(
                            scheduleList: scheduleList,
                            hospitalsList: hospitalsList,
                            onDateSelected: updateLocation,
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            final String patientUid = FirebaseAuth.instance.currentUser?.uid ?? "";
            if (patientUid.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SelectSlotPage(
                    doctorId: widget.doctorId,
                    patientUid: patientUid,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please login to book an appointment.")),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Book Appointment", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))]),
    );
  }
}

class ScheduleSection extends StatefulWidget {
  final List<Map<String, dynamic>> scheduleList;
  final List<dynamic> hospitalsList;
  final Function(String, String) onDateSelected;
  const ScheduleSection({super.key, required this.scheduleList, required this.hospitalsList, required this.onDateSelected});

  @override
  State<ScheduleSection> createState() => _ScheduleSectionState();
}

class _ScheduleSectionState extends State<ScheduleSection> {
  DateTime? selectedDate;

  String getAddressFromName(String hospitalName) {
    final hospital = widget.hospitalsList.firstWhere(
      (h) => h['hospitalName'] == hospitalName,
      orElse: () => null,
    );
    if (hospital != null && hospital['hospitalAddresses'] != null && hospital['hospitalAddresses'].isNotEmpty) {
      return hospital['hospitalAddresses'][0].toString();
    }
    return "Address not available";
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().add(Duration(days: index));
          String dayName = DateFormat('EEEE').format(date);
          final daySchedule = widget.scheduleList.firstWhere((s) => s['day']?.toString().toLowerCase() == dayName.toLowerCase(), orElse: () => {});

          if (daySchedule.isEmpty) return const SizedBox.shrink();

          if (selectedDate == null && index == 0) {
            selectedDate = date;
            String hName = daySchedule['hospitalName'] ?? "Clinic";
            Future.microtask(() => widget.onDateSelected(hName, getAddressFromName(hName)));
          }

          bool isSelected = selectedDate != null && DateFormat('yyyy-MM-dd').format(selectedDate!) == DateFormat('yyyy-MM-dd').format(date);

          return GestureDetector(
            onTap: () {
              setState(() { selectedDate = date; });
              String hName = daySchedule['hospitalName'] ?? "Clinic";
              widget.onDateSelected(hName, getAddressFromName(hName));
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: _ScheduleBox(DateFormat('EEE').format(date).toUpperCase(), DateFormat('dd').format(date), "${daySchedule['maxPatients'] ?? 0} Slots", isSelected),
            ),
          );
        },
      ),
    );
  }
}

class _ScheduleBox extends StatelessWidget {
  final String day, date, slots;
  final bool isSelected;
  const _ScheduleBox(this.day, this.date, this.slots, this.isSelected);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: isSelected ? Colors.blue : Colors.white, border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300, width: 2), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(day, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.grey)),
        Text(date, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
        Text(slots, style: TextStyle(fontSize: 8, color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold))
      ]),
    );
  }
}