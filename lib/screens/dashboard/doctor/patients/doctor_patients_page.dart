import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:appoinment_app/services/notification_services.dart';
import 'package:intl/intl.dart';

class DoctorPatientsPage extends StatefulWidget {
  const DoctorPatientsPage({super.key});

  @override
  State<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends State<DoctorPatientsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateAppointmentStatus(
      String appointmentId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      try {
        if (status == 'completed') {
          await NotificationService().showNotification(
            id: 601,
            title: 'Appointment Completed',
            body: 'The appointment has been marked as completed.',
          );
        } else if (status == 'cancelled') {
          await NotificationService().showNotification(
            id: 602,
            title: 'Appointment Cancelled',
            body: 'The appointment has been marked as cancelled.',
          );
        }
      } catch (err) {
        debugPrint('Notification error: $err');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment marked ${status.toLowerCase()}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update appointment: $e')),
      );
    }
  }

  Future<void> _showPatientDetails(
      String patientUid, Map<String, dynamic> summaryData) async {
    final patientDoc = await FirebaseFirestore.instance
        .collection('patients')
        .doc(patientUid)
        .get();
    final patientData = patientDoc.exists && patientDoc.data() != null
        ? patientDoc.data() as Map<String, dynamic>
        : {};

    final appointmentHistory = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .where('patientUid', isEqualTo: patientUid)
        .orderBy('date', descending: true)
        .get();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patientData['name'] ?? summaryData['name'] ?? 'Patient',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Phone: ${patientData['phone'] ?? 'Not available'}'),
                  const SizedBox(height: 4),
                  Text('Email: ${patientData['email'] ?? 'Not available'}'),
                  const SizedBox(height: 4),
                  Text('Age: ${patientData['age'] ?? 'N/A'}'),
                  const SizedBox(height: 4),
                  Text('Gender: ${patientData['gender'] ?? 'N/A'}'),
                  const SizedBox(height: 12),
                  Text('Medical Records',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  if (patientData['medicalRecords'] is List &&
                      (patientData['medicalRecords'] as List).isNotEmpty)
                    ...((patientData['medicalRecords'] as List).map((record) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text('- ${record.toString()}'),
                      );
                    }).toList())
                  else
                    const Text('No medical records available.',
                        style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  const Text('Appointment History',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (appointmentHistory.docs.isEmpty)
                    const Text('No appointment history found for this patient.',
                        style: TextStyle(color: Colors.grey))
                  else
                    ...appointmentHistory.docs.map((doc) {
                      final data = doc.data();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${data['date'] ?? 'Date'} • ${data['time'] ?? 'Time'}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Status: ${data['status'] ?? 'N/A'}'),
                            Text(
                                'Type: ${data['specialization'] ?? data['type'] ?? 'Consultation'}'),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _normalizeStatus(String status) {
    final normalized = status.toString().toLowerCase();
    if (normalized.contains('cancel')) return 'cancelled';
    if (normalized.contains('complete')) return 'completed';
    if (normalized.contains('pending') || normalized.contains('book'))
      return 'pending';
    return status.toString();
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    final patientName = data['patientName']?.toString().toLowerCase() ?? '';
    final status = data['status']?.toString().toLowerCase() ?? '';
    final type = data['type']?.toString().toLowerCase() ?? '';
    final specialization =
        data['specialization']?.toString().toLowerCase() ?? '';
    final notes = (data['notes'] ?? data['reason'] ?? data['description'] ?? '')
        .toString()
        .toLowerCase();
    return patientName.contains(query) ||
        status.contains(query) ||
        type.contains(query) ||
        specialization.contains(query) ||
        notes.contains(query);
  }

  Widget _buildStatusBadge(String status) {
    final normalized = _normalizeStatus(status);
    final color = normalized == 'completed'
        ? Colors.green
        : normalized == 'cancelled'
            ? Colors.red
            : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        normalized.toUpperCase(),
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view patients.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search appointments by patient, status or notes',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('doctorId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No appointments found yet. Once your appointments are booked, the list will appear here.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final allAppointments = snapshot.data!.docs
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {
                        'id': doc.id,
                        'data': data,
                        'dateTime': _parseAppointmentDateTime(data),
                      };
                    })
                    .where((appointment) => _matchesSearch(
                        appointment['data'] as Map<String, dynamic>))
                    .toList();

                final pendingAppointments =
                    allAppointments.where((appointment) {
                  final status = _normalizeStatus(
                      (appointment['data'] as Map<String, dynamic>)['status'] ??
                          'pending');
                  return status == 'pending';
                }).toList();

                final historyAppointments =
                    allAppointments.where((appointment) {
                  final status = _normalizeStatus(
                      (appointment['data'] as Map<String, dynamic>)['status'] ??
                          'pending');
                  return status == 'completed' || status == 'cancelled';
                }).toList();

                pendingAppointments.sort((a, b) => (b['dateTime'] as DateTime)
                    .compareTo(a['dateTime'] as DateTime));
                historyAppointments.sort((a, b) => (b['dateTime'] as DateTime)
                    .compareTo(a['dateTime'] as DateTime));

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 8),
                    const Text('Pending Appointments',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (pendingAppointments.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                            'No pending appointments at the moment.'),
                      )
                    else
                      ...pendingAppointments.map((appointment) {
                        final data =
                            appointment['data'] as Map<String, dynamic>;
                        final id = appointment['id'] as String;
                        final patientName =
                            data['patientName']?.toString() ?? 'Patient';
                        final date = data['date']?.toString() ?? 'TBD';
                        final time = data['time']?.toString() ?? 'TBD';
                        final patientUid = data['patientUid']?.toString() ?? '';
                        final notes = data['notes'] ??
                            data['reason'] ??
                            data['description'];
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: patientUid.isNotEmpty
                                ? () => _showPatientDetails(patientUid, data)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(patientName,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                      _buildStatusBadge('pending'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('$date • $time',
                                      style: TextStyle(
                                          color: Colors.grey.shade600)),
                                  if (notes != null &&
                                      notes.toString().trim().isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(notes.toString(),
                                        style: const TextStyle(
                                            color: Colors.black87)),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              _updateAppointmentStatus(
                                                  id, 'cancelled'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(
                                                color: Colors.red),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                          ),
                                          child: const Text('Cancel'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _updateAppointmentStatus(
                                                  id, 'completed'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                          ),
                                          child: const Text('Complete'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 16),
                    const Text('History',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (historyAppointments.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                            'No completed or cancelled appointments yet.'),
                      )
                    else
                      ...historyAppointments.map((appointment) {
                        final data =
                            appointment['data'] as Map<String, dynamic>;
                        final status = _normalizeStatus(
                            data['status']?.toString() ?? 'completed');
                        final patientName =
                            data['patientName']?.toString() ?? 'Patient';
                        final date = data['date']?.toString() ?? 'TBD';
                        final time = data['time']?.toString() ?? 'TBD';
                        final patientUid = data['patientUid']?.toString() ?? '';
                        final notes = data['notes'] ??
                            data['reason'] ??
                            data['description'];
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: patientUid.isNotEmpty
                                ? () => _showPatientDetails(patientUid, data)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(patientName,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                      _buildStatusBadge(status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('$date • $time',
                                      style: TextStyle(
                                          color: Colors.grey.shade600)),
                                  if (notes != null &&
                                      notes.toString().trim().isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(notes.toString(),
                                        style: const TextStyle(
                                            color: Colors.black87)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }

  DateTime _parseAppointmentDateTime(Map<String, dynamic> data) {
    final dateString = data['date']?.toString();
    final timeString = data['time']?.toString();
    try {
      if (dateString != null && dateString.isNotEmpty) {
        final date = DateTime.parse(dateString);
        if (timeString != null && timeString.isNotEmpty) {
          final parsedTime = DateFormat('hh:mm a').parseLoose(timeString);
          return DateTime(date.year, date.month, date.day, parsedTime.hour,
              parsedTime.minute);
        }
        return date;
      }
    } catch (_) {
      return DateTime.now();
    }
    return DateTime.now();
  }
}
