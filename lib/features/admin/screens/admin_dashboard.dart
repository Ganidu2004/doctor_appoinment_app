import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:appoinment_app/features/admin/widgets/custom_charts.dart';
import 'package:appoinment_app/features/admin/widgets/dialog_helpers.dart';
import 'admin_support_chats_page.dart';
import 'add_hospital_page.dart';
import 'package:appoinment_app/features/admin/screens/admin_payments_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _activeTab =
      0; // 0: Overview, 1: Appointments, 2: Doctors, 3: Patients, 4: Hospitals
  String _timeFilter = "Today"; // Today, Weekly, Monthly, All

  // Firestore references
  final CollectionReference _patientsCol =
      FirebaseFirestore.instance.collection('patients');
  final CollectionReference _doctorsCol =
      FirebaseFirestore.instance.collection('doctors');
  final CollectionReference _appointmentsCol =
      FirebaseFirestore.instance.collection('appointments');
  final CollectionReference _hospitalsCol =
      FirebaseFirestore.instance.collection('hospital');

  final Map<String, Color> _deptColors = {
    'Cardiology': const Color(0xFF2563EB),
    'Pediatrics': const Color(0xFF06B6D4),
    'Orthopedics': const Color(0xFF8B5CF6),
    'Neurology': const Color(0xFFF97316),
    'General Medicine': const Color(0xFF10B981),
  };

  DateTime? _parseAppointmentDate(String dateStr) {
    try {
      return DateFormat("MMMM d, yyyy").parse(dateStr);
    } catch (_) {}
    try {
      return DateFormat("yyyy-MM-dd").parse(dateStr);
    } catch (_) {}
    return DateTime.tryParse(dateStr);
  }

  bool _isWithinFilter(String dateStr) {
    final date = _parseAppointmentDate(dateStr);
    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_timeFilter == "Today") {
      return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    } else if (_timeFilter == "Weekly") {
      final weekAgo = today.subtract(const Duration(days: 7));
      return date.isAfter(weekAgo) &&
          date.isBefore(today.add(const Duration(days: 1)));
    } else if (_timeFilter == "Monthly") {
      final monthAgo = today.subtract(const Duration(days: 30));
      return date.isAfter(monthAgo) &&
          date.isBefore(today.add(const Duration(days: 1)));
    }
    return true; // "All"
  }

  Widget _buildHeroCard({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(Icons.payments_rounded, size: 100, color: Colors.white.withValues(alpha: 0.15)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required double cardWidth,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: iconBg.withValues(alpha: 0.5),
                blurRadius: 15,
                offset: const Offset(0, 6))
          ],
          border: Border.all(color: iconBg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(
      List<DocumentSnapshot> apptDocs,
      List<DocumentSnapshot> patientDocs,
      List<DocumentSnapshot> doctorDocs,
      List<DocumentSnapshot> hospitalDocs) {
    final totalPatients = patientDocs.length;
    final totalDoctors = doctorDocs.length;
    final totalAppts = apptDocs.length;


    final now = DateTime.now();
    final todayStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final todayNameStr = DateFormat('MMMM d, yyyy').format(now);
    final todayAppts = apptDocs.where((doc) {
      final d = (doc['date'] ?? '').toString();
      return d == todayNameStr || d.contains(todayStr);
    }).length;

    final List<DateTime> last7Days = List.generate(
        7,
        (i) => DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: 6 - i)));
    final List<double> trendsValues = List.filled(7, 0.0);
    final List<String> trendsLabels = [];

    for (int i = 0; i < 7; i++) {
      final day = last7Days[i];
      trendsLabels.add(DateFormat('EEE').format(day));

      final dateNameStr = DateFormat('MMMM d, yyyy').format(day);
      final dateIsoStr =
          '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

      final count = apptDocs.where((doc) {
        final d = (doc['date'] ?? '').toString();
        return d == dateNameStr || d.contains(dateIsoStr);
      }).length;
      trendsValues[i] = count.toDouble();
    }

    final double maxVal =
        trendsValues.reduce((curr, next) => curr > next ? curr : next);
    if (maxVal == 0) {
      trendsValues[0] = 140;
      trendsValues[1] = 170;
      trendsValues[2] = 160;
      trendsValues[3] = 220;
      trendsValues[4] = 180;
      trendsValues[5] = 110;
      trendsValues[6] = 190;
    }

    final Map<String, double> deptCounts = {
      'Cardiology': 0,
      'Pediatrics': 0,
      'Orthopedics': 0,
      'Neurology': 0,
      'General Medicine': 0,
    };

    int deptTotal = 0;
    for (var doc in apptDocs) {
      final spec = (doc['specialization'] ?? '').toString().toLowerCase();
      if (spec.contains('card')) {
        deptCounts['Cardiology'] = deptCounts['Cardiology']! + 1;
        deptTotal++;
      } else if (spec.contains('pedi')) {
        deptCounts['Pediatrics'] = deptCounts['Pediatrics']! + 1;
        deptTotal++;
      } else if (spec.contains('ortho')) {
        deptCounts['Orthopedics'] = deptCounts['Orthopedics']! + 1;
        deptTotal++;
      } else if (spec.contains('neur')) {
        deptCounts['Neurology'] = deptCounts['Neurology']! + 1;
        deptTotal++;
      } else if (spec.contains('general') ||
          spec.contains('practi') ||
          spec.isNotEmpty) {
        deptCounts['General Medicine'] = deptCounts['General Medicine']! + 1;
        deptTotal++;
      }
    }

    if (deptTotal == 0) {
      deptCounts['Cardiology'] = 30;
      deptCounts['Pediatrics'] = 17;
      deptCounts['Orthopedics'] = 13;
      deptCounts['Neurology'] = 22;
      deptCounts['General Medicine'] = 18;
      deptTotal = 100;
    }

    final Map<String, double> deptPercentages =
        deptCounts.map((k, v) => MapEntry(k, v / deptTotal));
    final filteredAppts = apptDocs
        .where((doc) => _isWithinFilter((doc['date'] ?? '').toString()))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _buildHeroCard(
                title: "Payment Details",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPaymentsPage())),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildHeaderCard(
                      title: "Total Patients",
                      value: NumberFormat('#,###')
                          .format(totalPatients > 0 ? totalPatients : 2453),
                      icon: Icons.people_outline,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      cardWidth: double.infinity,
                      onTap: () => setState(() => _activeTab = 3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHeaderCard(
                      title: "Today's Appointments",
                      value: todayAppts > 0 ? todayAppts.toString() : "42",
                      icon: Icons.calendar_today_outlined,
                      iconBg: const Color(0xFFECFDF5),
                      iconColor: const Color(0xFF10B981),
                      cardWidth: double.infinity,
                      onTap: () => setState(() => _activeTab = 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildHeaderCard(
                      title: "Available Doctors",
                      value: "${totalDoctors > 0 ? totalDoctors : 8} Active",
                      icon: Icons.medical_services_outlined,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFF97316),
                      cardWidth: double.infinity,
                      onTap: () => setState(() => _activeTab = 2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHeaderCard(
                      title: "Total Hospitals",
                      value: hospitalDocs.length.toString(),
                      icon: Icons.local_hospital_outlined,
                      iconBg: const Color(0xFFF5F3FF),
                      iconColor: const Color(0xFF7C3AED),
                      cardWidth: double.infinity,
                      onTap: () => setState(() => _activeTab = 4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Add Hospital Banner
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddHospitalPage()),
            ),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Expand Network",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Add a new hospital and grow your healthcare reach.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Icon(Icons.add_business_rounded, color: Color(0xFFE11D48), size: 28),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final double leftWidth = constraints.maxWidth > 900
                  ? (constraints.maxWidth - 20) * 0.6
                  : constraints.maxWidth;
              final double rightWidth = constraints.maxWidth > 900
                  ? (constraints.maxWidth - 20) * 0.4
                  : constraints.maxWidth;
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  Container(
                    width: leftWidth,
                    height: 380,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.blueGrey.withValues(alpha: 0.08),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.auto_graph_rounded, color: Colors.blue.shade600, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Text("Patient Trends",
                                style: TextStyle(
                                    fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: PatientTrendsChart(
                            values: trendsValues,
                            labels: trendsLabels,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: rightWidth,
                    height: 380,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.blueGrey.withValues(alpha: 0.08),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.donut_large_rounded, color: Colors.purple.shade600, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Text("Department Distribution",
                                style: TextStyle(
                                    fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              DepartmentDistributionChart(
                                departmentPercentages: deptPercentages,
                                departmentColors: _deptColors,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${(deptPercentages.values.fold(0.0, (s, e) => s + e) * 100).toInt()}%",
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1E293B)),
                                  ),
                                  Text("Total",
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: deptPercentages.keys.map((dept) {
                            final double pct = deptPercentages[dept] ?? 0.0;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _deptColors[dept]!.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _deptColors[dept],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "$dept ${(pct * 100).toStringAsFixed(0)}%",
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _deptColors[dept]),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        "Appointments List (${filteredAppts.isNotEmpty ? filteredAppts.length : totalAppts})",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _timeFilter,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                        items:
                            ["Today", "Weekly", "Monthly", "All"].map((filter) {
                          return DropdownMenuItem(
                              value: filter, child: Text(filter));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _timeFilter = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                filteredAppts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            "No appointments found for $_timeFilter",
                            style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredAppts.length,
                        itemBuilder: (context, index) {
                          final doc = filteredAppts[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final status = (data['status'] ?? 'Booked').toString();
                          final patientName = data['patientName']?.toString() ?? 'Unknown Patient';
                          final doctorName = data['doctorName']?.toString() ?? 'Doctor';
                          final time = data['time']?.toString() ?? '09:00 AM';
                          final specialization = data['specialization']?.toString() ?? 'General Medicine';
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => AdminDialogHelpers.showAppointmentDetails(context, doc),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.blue.shade50,
                                        child: Text(
                                          patientName.isNotEmpty ? patientName.substring(0, 1).toUpperCase() : 'U',
                                          style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              patientName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.medical_services_outlined, size: 14, color: Colors.blue[400]),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    "Dr. $doctorName • $specialization",
                                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[400]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  time,
                                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Status Badge
                                      Container(
                                        constraints: const BoxConstraints(maxWidth: 100),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AdminDialogHelpers.getStatusBgColor(status),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          status,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: AdminDialogHelpers.getStatusTextColor(status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab(List<DocumentSnapshot> docs) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Real-Time Appointments Registry",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: docs.isEmpty
              ? const Center(child: Text("No registered appointments yet."))
              : ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final status = (data['status'] ?? 'Booked').toString();
                    final patientUid = data['patientUid']?.toString() ?? '';
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => AdminDialogHelpers.showAppointmentDetails(
                            context, doc),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              patientUid.isEmpty
                                  ? CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.blue.shade50,
                                      child: Icon(Icons.person,
                                          color: Colors.blue.shade300,
                                          size: 26),
                                    )
                                  : FutureBuilder<DocumentSnapshot>(
                                      future:
                                          _patientsCol.doc(patientUid).get(),
                                      builder: (context, snapshot) {
                                        String imageUrl = '';
                                        if (snapshot.connectionState ==
                                                ConnectionState.done &&
                                            snapshot.hasData &&
                                            snapshot.data!.exists) {
                                          final patientData = snapshot.data!
                                              .data() as Map<String, dynamic>?;
                                          imageUrl =
                                              patientData?['profileImageUrl'] ??
                                                  '';
                                        }
                                        return Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.blue.shade50,
                                                width: 2),
                                          ),
                                          child: CircleAvatar(
                                            radius: 24,
                                            backgroundColor:
                                                Colors.grey.shade100,
                                            backgroundImage: imageUrl.isNotEmpty
                                                ? NetworkImage(imageUrl)
                                                : null,
                                            child: imageUrl.isEmpty
                                                ? Icon(Icons.person,
                                                    color: Colors.blue.shade300,
                                                    size: 26)
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['patientName'] ?? 'Unknown Patient',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.medical_services_outlined,
                                            size: 13, color: Colors.blue[400]),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            "Dr. ${data['doctorName'] ?? 'Doctor'}",
                                            style: TextStyle(
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        Icon(Icons.calendar_today_outlined,
                                            size: 12, color: Colors.grey[400]),
                                        Text(
                                          data['date'] ?? 'N/A',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 11),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.access_time_rounded,
                                            size: 12, color: Colors.grey[400]),
                                        Text(
                                          data['time'] ?? 'N/A',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "Fee: LKR ${(data['consultationFee'] ?? 0).toString()}",
                                        style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                constraints: const BoxConstraints(maxWidth: 110),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AdminDialogHelpers.getStatusBgColor(
                                      status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color:
                                        AdminDialogHelpers.getStatusTextColor(
                                            status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDoctorsTab(List<DocumentSnapshot> docs) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Medical Staff (${docs.length})",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Color(0xFF1E293B)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => AdminDialogHelpers.showAddDoctor(context),
                  icon: const Icon(Icons.add_rounded,
                      size: 18, color: Colors.white),
                  label: const Text("Add Doctor",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: docs.isEmpty
              ? const Center(
                  child: Text("No registered doctors in the database.",
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.w500)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Doctor';
                    final spec = data['specialization'] ?? 'Specialist';
                    final exp = data['experience'] ?? 0;
                    final String imageUrl = data['profileImageUrl'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueGrey.withValues(alpha: 0.08),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Decorative background pattern
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Icon(
                              Icons.health_and_safety_rounded,
                              size: 110,
                              color: Colors.blue.withValues(alpha: 0.04),
                            ),
                          ),
                          // Status indicator line
                          Positioned(
                            left: 0,
                            top: 24,
                            bottom: 24,
                            child: Container(
                              width: 5,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade400,
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                // Modern Avatar
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    image: imageUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(imageUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: imageUrl.isEmpty
                                      ? Icon(Icons.medical_services_rounded,
                                          color: Colors.blue.shade300, size: 36)
                                      : null,
                                ),
                                const SizedBox(width: 18),
                                // Doctor Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Dr. $name",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 17,
                                            color: Color(0xFF1E293B)),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              spec,
                                              style: TextStyle(
                                                  color: Colors.blue.shade700,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.star_rounded,
                                                    size: 14,
                                                    color: Colors.amber.shade600),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "$exp Yrs Exp",
                                                  style: TextStyle(
                                                      color: Colors.amber.shade800,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Action Button
                                InkWell(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text("Remove Doctor"),
                                        content: Text(
                                            "Are you sure you want to delete Dr. $name from the registry?"),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text("Cancel")),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text("Delete",
                                                style:
                                                    TextStyle(color: Colors.red)),
                                          )
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await doc.reference.delete();
                                      final schedules = await doc.reference
                                          .collection('schedules')
                                          .get();
                                      for (var s in schedules.docs) {
                                        await s.reference.delete();
                                      }
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(Icons.person_remove_rounded,
                                        color: Colors.red.shade600, size: 22),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPatientsTab(List<DocumentSnapshot> docs) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Patient Directory (${docs.length})",
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: docs.isEmpty
              ? const Center(
                  child: Text("No registered patients in database.",
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.w500)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Patient';
                    final email = data['email'] ?? 'No Email';
                    final isBlocked = data['isBlocked'] ?? false;
                    final String imageUrl = data['profileImageUrl'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueGrey.withValues(alpha: 0.08),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Decorative background pattern
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Icon(
                              Icons.personal_injury_rounded,
                              size: 110,
                              color: isBlocked ? Colors.red.withValues(alpha: 0.04) : Colors.blue.withValues(alpha: 0.04),
                            ),
                          ),
                          // Status indicator line
                          Positioned(
                            left: 0,
                            top: 24,
                            bottom: 24,
                            child: Container(
                              width: 5,
                              decoration: BoxDecoration(
                                color: isBlocked ? Colors.red.shade400 : Colors.teal.shade400,
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                // Modern Avatar
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    image: imageUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(imageUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: imageUrl.isEmpty
                                      ? Icon(Icons.person_rounded,
                                          color: Colors.grey.shade400, size: 36)
                                      : null,
                                ),
                                const SizedBox(width: 18),
                                // Patient Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 17,
                                                color: isBlocked ? Colors.grey.shade500 : const Color(0xFF1E293B),
                                                decoration: isBlocked
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          if (isBlocked)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(color: Colors.red.shade100),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.block, size: 12, color: Colors.red.shade600),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "Blocked",
                                                    style: TextStyle(
                                                        color: Colors.red.shade700,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 10),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.email_rounded, size: 15, color: Colors.blueGrey.shade300),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              email,
                                              style: TextStyle(
                                                  color: Colors.blueGrey.shade600,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          // Small chip indicating status visually
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isBlocked ? Colors.red.shade50 : Colors.teal.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              isBlocked ? "Inactive" : "Active Patient",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isBlocked ? Colors.red.shade700 : Colors.teal.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Action Buttons in a column
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () async {
                                        await doc.reference
                                            .update({'isBlocked': !isBlocked});
                                      },
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isBlocked
                                              ? Colors.green.shade50
                                              : Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          isBlocked
                                              ? Icons.lock_open_rounded
                                              : Icons.lock_outline_rounded,
                                          color: isBlocked
                                              ? Colors.green.shade700
                                              : Colors.orange.shade700,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    InkWell(
                                      onTap: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text("Delete Patient"),
                                            content: Text(
                                                "Delete $name permanently from database?"),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: const Text("Cancel")),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text("Delete",
                                                    style:
                                                        TextStyle(color: Colors.red)),
                                              )
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await doc.reference.delete();
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(Icons.delete_sweep_outlined,
                                            color: Colors.red.shade600, size: 20),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHospitalsTab(List<DocumentSnapshot> docs) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Partner Hospitals (${docs.length})",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Color(0xFF1E293B)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddHospitalPage(),
                    ),
                  ),
                  icon: const Icon(Icons.add_business_rounded,
                      size: 18, color: Colors.white),
                  label: const Text("Add Hospital",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: docs.isEmpty
              ? const Center(
                  child: Text(
                      "No registered hospitals. Click Add Hospital to register one.",
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.w500)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Hospital Name';
                    final address = data['address'] ?? 'No Address';
                    final district = data['district']?.toString() ?? '';
                    final contact = data['contact'] ?? 'No Contact';
                    final charges = data['charges'] is num
                        ? (data['charges'] as num).toDouble()
                        : 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueGrey.withValues(alpha: 0.08),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Decorative background pattern
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Icon(
                              Icons.local_hospital_rounded,
                              size: 110,
                              color: Colors.red.withValues(alpha: 0.03),
                            ),
                          ),
                          // Status indicator line
                          Positioned(
                            left: 0,
                            top: 24,
                            bottom: 24,
                            child: Container(
                              width: 5,
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Modern Avatar
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(Icons.apartment_rounded,
                                      color: Colors.red.shade300, size: 36),
                                ),
                                const SizedBox(width: 18),
                                // Hospital Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 17,
                                            color: Color(0xFF1E293B)),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.location_on_rounded, size: 15, color: Colors.blueGrey.shade400),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              "$address${district.isNotEmpty ? ', $district' : ''}",
                                              style: TextStyle(
                                                  color: Colors.blueGrey.shade600,
                                                  fontSize: 13,
                                                  height: 1.3,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.phone_rounded,
                                                    size: 13,
                                                    color: Colors.blue.shade600),
                                                const SizedBox(width: 4),
                                                Text(
                                                  contact,
                                                  style: TextStyle(
                                                      color: Colors.blue.shade700,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.payments_rounded,
                                                    size: 13,
                                                    color: Colors.green.shade600),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "LKR ${charges.toStringAsFixed(0)}",
                                                  style: TextStyle(
                                                      color: Colors.green.shade800,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Action Button
                                InkWell(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text("Delete Hospital"),
                                        content: Text(
                                            "Delete $name permanently from database?"),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text("Cancel")),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text("Delete",
                                                style: TextStyle(color: Colors.red)),
                                          )
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await doc.reference.delete();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(Icons.domain_disabled_rounded,
                                        color: Colors.red.shade600, size: 22),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings,
                  color: Color(0xFF2563EB), size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'DocConnect Admin',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.black87),
            tooltip: "Support Chats",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminSupportChatsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            tooltip: "Logout",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Sign Out"),
                  content: const Text(
                      "Are you sure you want to sign out from the Admin portal?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("Cancel")),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text("Sign Out",
                          style: TextStyle(color: Colors.red)),
                    )
                  ],
                ),
              );
              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
              }
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _appointmentsCol.snapshots(),
        builder: (context, apptsSnap) {
          final List<DocumentSnapshot> apptDocs = apptsSnap.data?.docs ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream: _patientsCol.snapshots(),
            builder: (context, patientsSnap) {
              final List<DocumentSnapshot> patientDocs =
                  patientsSnap.data?.docs ?? [];

              return StreamBuilder<QuerySnapshot>(
                stream: _doctorsCol.snapshots(),
                builder: (context, doctorsSnap) {
                  final List<DocumentSnapshot> doctorDocs =
                      doctorsSnap.data?.docs ?? [];

                  return StreamBuilder<QuerySnapshot>(
                    stream: _hospitalsCol.snapshots(),
                    builder: (context, hospitalsSnap) {
                      final List<DocumentSnapshot> hospitalDocs =
                          hospitalsSnap.data?.docs ?? [];

                      Widget activeWidget;
                      switch (_activeTab) {
                        case 1:
                          activeWidget = _buildAppointmentsTab(apptDocs);
                          break;
                        case 2:
                          activeWidget = _buildDoctorsTab(doctorDocs);
                          break;
                        case 3:
                          activeWidget = _buildPatientsTab(patientDocs);
                          break;
                        case 4:
                          activeWidget = _buildHospitalsTab(hospitalDocs);
                          break;
                        case 0:
                        default:
                          activeWidget = _buildOverview(
                              apptDocs, patientDocs, doctorDocs, hospitalDocs);
                          break;
                      }

                      return activeWidget;
                    },
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _activeTab,
        onTap: (index) => setState(() => _activeTab = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: "Overview"),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: "Appointments"),
          BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_outlined),
              activeIcon: Icon(Icons.medical_services),
              label: "Doctors"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: "Patients"),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_hospital_outlined),
              activeIcon: Icon(Icons.local_hospital),
              label: "Hospitals"),
        ],
      ),
    );
  }
}
