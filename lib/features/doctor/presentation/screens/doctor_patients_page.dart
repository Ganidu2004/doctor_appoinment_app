import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:appoinment_app/features/doctor/presentation/widgets/doctor_patient_ehr_modal.dart';

class DoctorPatientsPage extends StatefulWidget {
  const DoctorPatientsPage({super.key});

  @override
  State<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends State<DoctorPatientsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

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

  String _formatName(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty) return 'Patient';
    final words = rawName.trim().split(' ').where((w) => w.isNotEmpty).map((word) {
      if (word.length <= 1) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
    return words;
  }

  Future<void> _showPatientDetails(String patientUid, Map<String, dynamic> patientGroup) async {
    Map<String, dynamic> patientData = {};
    if (patientUid.isNotEmpty) {
      final patientDoc = await FirebaseFirestore.instance.collection('patients').doc(patientUid).get();
      if (patientDoc.exists && patientDoc.data() != null) {
        patientData = patientDoc.data() as Map<String, dynamic>;
      }
    }

    final String patientName = patientGroup['patientName'] ?? 'Patient';

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DoctorPatientEhrModal(
        patientUid: patientUid,
        patientName: patientName,
        initialPatientData: patientData,
      ),
    );
  }

  String _normalizeStatus(String status) {
    final normalized = status.toString().toLowerCase();
    if (normalized.contains('cancel')) return 'cancelled';
    if (normalized.contains('complete')) return 'completed';
    if (normalized.contains('pending') || normalized.contains('book')) {
      return 'pending';
    }
    return status.toString();
  }

  bool _matchesPatientSearch(Map<String, dynamic> patientGroup) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    final patientName = (patientGroup['patientName'] ?? '').toString().toLowerCase();
    final appointments = patientGroup['appointments'] as List? ?? [];
    bool notesMatch = false;
    for (var appt in appointments) {
      final notes = (appt['notes'] ?? appt['reason'] ?? appt['description'] ?? '').toString().toLowerCase();
      if (notes.contains(query)) {
        notesMatch = true;
        break;
      }
    }
    return patientName.contains(query) || notesMatch;
  }

  Widget _buildStatusBadge(String status) {
    final normalized = _normalizeStatus(status);
    Color color;
    Color bg;
    Color border;
    String label;
    IconData icon;

    if (normalized == 'completed') {
      color = const Color(0xFF047857);
      bg = const Color(0xFFECFDF5);
      border = const Color(0xFFA7F3D0);
      label = 'COMPLETED';
      icon = Icons.check_circle_rounded;
    } else if (normalized == 'cancelled') {
      color = const Color(0xFFB91C1C);
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFECACA);
      label = 'CANCELLED';
      icon = Icons.cancel_rounded;
    } else {
      color = const Color(0xFFB45309);
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      label = 'PENDING';
      icon = Icons.bolt_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10.5, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view patients.'));
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              // Search Input Box
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Search patients by name or notes...',
                    hintStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0EA5E9)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Filter Chips Carousel
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'With Pending', 'Completed'].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                                )
                              : null,
                          color: isSelected ? null : (isDark ? const Color(0xFF1E293B) : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0EA5E9) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          filter == 'All' ? 'All Patients' : filter,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Stream Builder Unique Patients List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('appointments')
                      .where('doctorId', isEqualTo: user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyPatientsState();
                    }

                    // Group appointments by unique patient
                    final Map<String, Map<String, dynamic>> uniquePatientsMap = {};

                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final patientUid = (data['patientUid'] ?? '').toString();
                      final patientName = (data['patientName'] ?? 'Patient').toString();
                      final key = patientUid.isNotEmpty ? patientUid : patientName.toLowerCase().trim();

                      if (!uniquePatientsMap.containsKey(key)) {
                        uniquePatientsMap[key] = {
                          'patientUid': patientUid,
                          'patientName': patientName,
                          'appointments': [data],
                          'appointmentIds': [doc.id],
                          'latestAppointment': data,
                          'latestDateTime': _parseAppointmentDateTime(data),
                        };
                      } else {
                        final existing = uniquePatientsMap[key]!;
                        (existing['appointments'] as List).add(data);
                        (existing['appointmentIds'] as List).add(doc.id);
                        final dt = _parseAppointmentDateTime(data);
                        if (dt.isAfter(existing['latestDateTime'] as DateTime)) {
                          existing['latestDateTime'] = dt;
                          existing['latestAppointment'] = data;
                        }
                      }
                    }

                    var uniquePatientsList = uniquePatientsMap.values
                        .where((patientGroup) => _matchesPatientSearch(patientGroup))
                        .toList();

                    // Apply filter
                    if (_selectedFilter == 'With Pending') {
                      uniquePatientsList = uniquePatientsList.where((pGroup) {
                        final appts = pGroup['appointments'] as List;
                        return appts.any((a) => _normalizeStatus((a['status'] ?? '').toString()) == 'pending');
                      }).toList();
                    } else if (_selectedFilter == 'Completed') {
                      uniquePatientsList = uniquePatientsList.where((pGroup) {
                        final appts = pGroup['appointments'] as List;
                        return appts.any((a) => _normalizeStatus((a['status'] ?? '').toString()) == 'completed');
                      }).toList();
                    }

                    // Sort newest visit patient first
                    uniquePatientsList.sort((a, b) => (b['latestDateTime'] as DateTime).compareTo(a['latestDateTime'] as DateTime));

                    if (uniquePatientsList.isEmpty) {
                      return _buildEmptyPatientsState();
                    }

                    return ListView.builder(
                      itemCount: uniquePatientsList.length,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemBuilder: (context, index) {
                        final patientGroup = uniquePatientsList[index];
                        final patientName = _formatName(patientGroup['patientName']?.toString());
                        final patientUid = patientGroup['patientUid']?.toString() ?? '';
                        final appointments = patientGroup['appointments'] as List;
                        final latestData = patientGroup['latestAppointment'] as Map<String, dynamic>;
                        final latestStatus = (latestData['status'] ?? 'pending').toString();
                        final latestDate = latestData['date']?.toString() ?? 'TBD';
                        final latestTime = latestData['time']?.toString() ?? 'TBD';

                        return _buildUniquePatientCard(
                          context: context,
                          patientUid: patientUid,
                          patientName: patientName,
                          totalAppointments: appointments.length,
                          latestDate: latestDate,
                          latestTime: latestTime,
                          latestStatus: latestStatus,
                          patientGroup: patientGroup,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUniquePatientCard({
    required BuildContext context,
    required String patientUid,
    required String patientName,
    required int totalAppointments,
    required String latestDate,
    required String latestTime,
    required String latestStatus,
    required Map<String, dynamic> patientGroup,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String initial = patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P';
    final normalized = _normalizeStatus(latestStatus);
    Color statusColor = normalized == 'completed'
        ? const Color(0xFF047857)
        : normalized == 'cancelled'
            ? const Color(0xFFB91C1C)
            : const Color(0xFFB45309);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Left Status Accent Indicator Strip
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                color: statusColor,
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _showPatientDetails(patientUid, patientGroup),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Patient Initial Avatar Box
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE0F2FE),
                            border: Border.all(color: isDark ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD), width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: TextStyle(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patientName,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$totalAppointments Visit${totalAppointments == 1 ? '' : 's'}',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(latestStatus),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Latest Visit Date Surface
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF0EA5E9)),
                          const SizedBox(width: 6),
                          Text(
                            'Latest: $latestDate • $latestTime',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Action Button Row
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showPatientDetails(patientUid, patientGroup),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          side: BorderSide(color: isDark ? const Color(0xFF0EA5E9) : const Color(0xFF0EA5E9), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.description_outlined, size: 18, color: Color(0xFF0EA5E9)),
                        label: Text(
                          'Patient Record',
                          style: TextStyle(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPatientsState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFF0EA5E9)),
            ),
            const SizedBox(height: 16),
            Text(
              'No Patients Found for This Doctor',
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Only patients who have scheduled appointments with you will be listed here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13),
            ),
          ],
        ),
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
          return DateTime(date.year, date.month, date.day, parsedTime.hour, parsedTime.minute);
        }
        return date;
      }
    } catch (_) {
      return DateTime.now();
    }
    return DateTime.now();
  }
}
