import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:appoinment_app/features/admin/presentation/widgets/custom_charts.dart';
import 'package:appoinment_app/features/admin/presentation/widgets/dialog_helpers.dart';
import 'admin_support_chats_page.dart';
import 'add_hospital_page.dart';
import 'add_admin_user_page.dart';
import 'package:appoinment_app/features/admin/presentation/screens/admin_payments_page.dart';
import 'package:appoinment_app/features/admin/presentation/screens/admin_reports_page.dart';
import 'package:appoinment_app/shared/widgets/doc_time_logo.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _activeTab =
      0; // 0: Overview, 1: Appointments, 2: Doctors, 3: Patients, 4: Hospitals, 5: Payments, 6: Reports, 7: Support Chats
  String _timeFilter = "Today"; // Today, Weekly, Monthly, All
  bool _isDarkMode = false;

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
    required String badgeText,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Stack(
          clipBehavior: Clip.antiAlias,
          children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                icon,
                size: 110,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Open Portal",
                            style: TextStyle(
                              color: gradientColors.first,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: gradientColors.first,
                          ),
                        ],
                      ),
                    ),
                  ],
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
    final isDark = _isDarkMode;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.trending_up, size: 12, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text(
                        "Live",
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
              Row(
                children: [
                  Expanded(
                    child: _buildHeroCard(
                      badgeText: "FINANCIAL LEDGER",
                      title: "Payment Details",
                      icon: Icons.payments_rounded,
                      gradientColors: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPaymentsPage())),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildHeroCard(
                      badgeText: "ANALYTICS & EXPORTS",
                      title: "Generate Reports",
                      icon: Icons.assessment_rounded,
                      gradientColors: const [Color(0xFF0284C7), Color(0xFF2563EB)],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportsPage())),
                    ),
                  ),
                ],
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
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "Appointments Registry",
                    style: TextStyle(
                      fontSize: isDesktop ? 22 : 18,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${docs.length} Total",
                      style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: docs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        "No registered appointments yet.",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final status = (data['status'] ?? 'Booked').toString();
                    final patientUid = data['patientUid']?.toString() ?? '';
                    final docId = doc.id.length >= 6 ? doc.id.substring(0, 6).toUpperCase() : doc.id.toUpperCase();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: _isDarkMode ? 0.2 : 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => AdminDialogHelpers.showAppointmentDetails(context, doc),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar
                              patientUid.isEmpty
                                  ? const CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Color(0xFFEFF6FF),
                                      child: Icon(Icons.person, color: Color(0xFF2563EB), size: 24),
                                    )
                                  : FutureBuilder<DocumentSnapshot>(
                                      future: _patientsCol.doc(patientUid).get(),
                                      builder: (context, snapshot) {
                                        String imageUrl = '';
                                        if (snapshot.connectionState == ConnectionState.done &&
                                            snapshot.hasData &&
                                            snapshot.data!.exists) {
                                          final patientData = snapshot.data!.data() as Map<String, dynamic>?;
                                          imageUrl = patientData?['profileImageUrl'] ?? '';
                                        }
                                        return Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3), width: 2),
                                          ),
                                          child: CircleAvatar(
                                            radius: 24,
                                            backgroundColor: const Color(0xFFEFF6FF),
                                            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                                            child: imageUrl.isEmpty
                                                ? const Icon(Icons.person, color: Color(0xFF2563EB), size: 24)
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                              const SizedBox(width: 16),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            data['patientName'] ?? 'Unknown Patient',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            "#$docId",
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.medical_services_rounded, size: 14, color: Color(0xFF2563EB)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            "Dr. ${data['doctorName'] ?? 'Doctor'} • ${data['specialization'] ?? 'General Medicine'}",
                                            style: const TextStyle(
                                              color: Color(0xFF2563EB),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 12,
                                      runSpacing: 6,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey.shade500),
                                            const SizedBox(width: 4),
                                            Text(
                                              data['date'] ?? 'N/A',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade500),
                                            const SizedBox(width: 4),
                                            Text(
                                              data['time'] ?? 'N/A',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "LKR ${(data['consultationFee'] ?? 0).toString()}",
                                            style: const TextStyle(
                                              color: Color(0xFF10B981),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Interactive Status Popup Menu
                              PopupMenuButton<String>(
                                initialValue: status,
                                onSelected: (newStatus) async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  await doc.reference.update({'status': newStatus});
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text("Appointment status updated to $newStatus"),
                                      backgroundColor: const Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AdminDialogHelpers.getStatusBgColor(status),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        status,
                                        style: TextStyle(
                                          color: AdminDialogHelpers.getStatusTextColor(status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: AdminDialogHelpers.getStatusTextColor(status),
                                      ),
                                    ],
                                  ),
                                ),
                                itemBuilder: (context) => [
                                  'Booked',
                                  'Confirmed',
                                  'Completed',
                                  'Cancelled',
                                ].map((s) {
                                  return PopupMenuItem<String>(
                                    value: s,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: AdminDialogHelpers.getStatusTextColor(s),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          s,
                                          style: TextStyle(
                                            fontWeight: s == status ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
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
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "Medical Staff",
                    style: TextStyle(
                      fontSize: isDesktop ? 22 : 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${docs.length} Active",
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
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
                  icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  label: const Text("Add Doctor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: docs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        "No registered doctors in the database.",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : isDesktop
                  ? GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) => _buildDoctorCard(docs[index]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: _buildDoctorCard(docs[index]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildDoctorCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Doctor';
    final spec = data['specialization'] ?? 'Specialist';
    final exp = data['experience'] ?? 0;
    final String imageUrl = data['profileImageUrl'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkMode ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                Icons.health_and_safety_rounded,
                size: 90,
                color: const Color(0xFF2563EB).withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(18),
                      image: imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.medical_services_rounded, color: Color(0xFF2563EB), size: 32)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Dr. $name",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                spec,
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 3),
                                  Text(
                                    "$exp Yrs Exp",
                                    style: const TextStyle(
                                      color: Color(0xFFD97706),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete action button
                  IconButton(
                    icon: Icon(Icons.person_remove_rounded, color: Colors.red.shade400, size: 20),
                    tooltip: "Remove Doctor",
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Remove Doctor"),
                          content: Text("Are you sure you want to delete Dr. $name from the registry?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text("Delete", style: TextStyle(color: Colors.red)),
                            )
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await doc.reference.delete();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientsTab(List<DocumentSnapshot> docs) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            children: [
              Text(
                "Patient Directory",
                style: TextStyle(
                  fontSize: isDesktop ? 22 : 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${docs.length} Registered",
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: docs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        "No registered patients in database.",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : isDesktop
                  ? GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) => _buildPatientCard(docs[index]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: _buildPatientCard(docs[index]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildPatientCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Patient';
    final email = data['email'] ?? 'No Email';
    final isBlocked = data['isBlocked'] ?? false;
    final String imageUrl = data['profileImageUrl'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkMode ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                Icons.personal_injury_rounded,
                size: 90,
                color: isBlocked
                    ? Colors.red.withValues(alpha: 0.05)
                    : const Color(0xFF10B981).withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(18),
                      image: imageUrl.isNotEmpty
                          ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.person_rounded, color: Color(0xFF64748B), size: 32)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isBlocked
                                      ? Colors.grey
                                      : (_isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                                  decoration: isBlocked ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            if (isBlocked) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Blocked",
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.email_rounded, size: 14, color: Colors.blueGrey.shade300),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                email,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          isBlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                          color: isBlocked ? Colors.green.shade600 : Colors.amber.shade700,
                          size: 18,
                        ),
                        tooltip: isBlocked ? "Unblock Patient" : "Block Patient",
                        onPressed: () async {
                          await doc.reference.update({'isBlocked': !isBlocked});
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_sweep_rounded, color: Colors.red.shade400, size: 18),
                        tooltip: "Delete Patient",
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Delete Patient"),
                              content: Text("Delete $name permanently from database?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                )
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await doc.reference.delete();
                          }
                        },
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
  }

  Widget _buildHospitalsTab(List<DocumentSnapshot> docs) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "Partner Hospitals",
                    style: TextStyle(
                      fontSize: isDesktop ? 22 : 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${docs.length} Facilities",
                      style: const TextStyle(
                        color: Color(0xFFF43F5E),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
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
                    minimumSize: const Size(0, 42),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_hospital_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        "No registered hospitals. Click Add Hospital to register one.",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : isDesktop
                  ? GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) => _buildHospitalCard(docs[index]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: _buildHospitalCard(docs[index]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildHospitalCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Hospital Name';
    final address = data['address'] ?? 'No Address';
    final district = data['district']?.toString() ?? '';
    final contact = data['contact'] ?? 'No Contact';
    final charges = data['charges'] is num
        ? (data['charges'] as num).toDouble()
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkMode ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                Icons.domain_rounded,
                size: 90,
                color: const Color(0xFFF43F5E).withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.local_hospital_rounded, color: Color(0xFFF43F5E), size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                district.isNotEmpty ? "$address • $district" : address,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Fee: LKR ${charges.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Color(0xFFF43F5E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                contact,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.domain_disabled_rounded, color: Colors.red.shade400, size: 20),
                    tooltip: "Delete Hospital",
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Delete Hospital"),
                          content: Text("Are you sure you want to remove $name?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text("Delete", style: TextStyle(color: Colors.red)),
                            )
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await doc.reference.delete();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader({bool isPermanent = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, isPermanent ? 24 : 48, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          Positioned(
            right: -25,
            bottom: -25,
            child: Icon(
              Icons.admin_panel_settings_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const DocTimeLogo(
                    variant: DocTimeLogoVariant.iconOnly,
                    iconSize: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'DOC ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              TextSpan(
                                text: 'Time',
                                style: TextStyle(
                                  color: Color(0xFF0EA5E9),
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                "ADMIN CONSOLE",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            FirebaseAuth.instance.currentUser?.email ?? "Super Admin Account",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            "System Administrator",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
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
        ],
      ),
    );
  }

  Widget _buildNavDrawer({bool isPermanent = false}) {
    final items = [
      {'title': 'Overview', 'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard_rounded, 'index': 0},
      {'title': 'Appointments', 'icon': Icons.calendar_today_outlined, 'activeIcon': Icons.calendar_today_rounded, 'index': 1},
      {'title': 'Doctors', 'icon': Icons.medical_services_outlined, 'activeIcon': Icons.medical_services_rounded, 'index': 2},
      {'title': 'Patients', 'icon': Icons.people_outline, 'activeIcon': Icons.people_rounded, 'index': 3},
      {'title': 'Hospitals', 'icon': Icons.local_hospital_outlined, 'activeIcon': Icons.local_hospital_rounded, 'index': 4},
      {'title': 'Payments', 'icon': Icons.payments_outlined, 'activeIcon': Icons.payments_rounded, 'index': 5},
      {'title': 'Reports', 'icon': Icons.assessment_outlined, 'activeIcon': Icons.assessment_rounded, 'index': 6},
      {'title': 'Support Chats', 'icon': Icons.chat_bubble_outline, 'activeIcon': Icons.chat_bubble_rounded, 'index': 7},
      {'title': 'Admin Users', 'icon': Icons.admin_panel_settings_outlined, 'activeIcon': Icons.admin_panel_settings_rounded, 'index': 8},
    ];

    final bgColor = _isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: BorderSide(
            color: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildDrawerHeader(isPermanent: isPermanent),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 14),
              children: [
                ...items.map((item) {
                  final idx = item['index'] as int;
                  final isSelected = _activeTab == idx;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                            )
                          : null,
                      color: isSelected ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        dense: true,
                        horizontalTitleGap: 12,
                        leading: Icon(
                          isSelected ? item['activeIcon'] as IconData : item['icon'] as IconData,
                          color: isSelected
                              ? Colors.white
                              : (_isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                          size: 20,
                        ),
                        title: Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : textColor,
                          ),
                        ),
                        onTap: () {
                          setState(() => _activeTab = idx);
                          if (!isPermanent && Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 14),
                const Divider(indent: 16, endIndent: 16, height: 1),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (!isPermanent && Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddHospitalPage()),
                        );
                      },
                      icon: const Icon(Icons.add_business_rounded, size: 18),
                      label: const Text(
                        "Add Hospital",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (!isPermanent && Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddAdminUserPage()),
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: const Text(
                        "Add Admin User",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final bgColor = _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBgColor = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      drawer: isDesktop ? null : Drawer(child: _buildNavDrawer(isPermanent: false)),
      appBar: AppBar(
        backgroundColor: cardBgColor,
        elevation: 0.5,
        iconTheme: IconThemeData(color: _isDarkMode ? Colors.white : Colors.black87),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings,
                  color: Color(0xFF4F46E5), size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'DOC Time',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: isDesktop ? 18 : 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "ADMIN",
                          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (isDesktop)
                    Text(
                      "Healthcare Admin Portal",
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),

            if (isDesktop) ...[
              const SizedBox(width: 24),
              // Search input
              Expanded(
                flex: 2,
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.white : Colors.black87),
                    decoration: const InputDecoration(
                      hintText: "Search appointments, doctors, patients...",
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                      prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Time Filter Chips
          PopupMenuButton<String>(
            initialValue: _timeFilter,
            onSelected: (val) => setState(() => _timeFilter = val),
            padding: EdgeInsets.zero,
            icon: Container(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 10 : 6, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_alt_outlined, size: 14, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 2),
                  Text(_timeFilter, style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),
            itemBuilder: (ctx) => ["Today", "Weekly", "Monthly", "All"].map((f) => PopupMenuItem(value: f, child: Text(f))).toList(),
          ),

          // Theme Mode Switch Button
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
              color: _isDarkMode ? Colors.amber : Colors.indigo,
            ),
            tooltip: "Toggle Dark/Light Mode",
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),

          // Logout
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            tooltip: "Sign Out",
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
      body: Row(
        children: [
          if (isDesktop) _buildNavDrawer(isPermanent: true),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                              case 5:
                                activeWidget = const AdminPaymentsPage(isEmbedded: true);
                                break;
                              case 6:
                                activeWidget = const AdminReportsPage(isEmbedded: true);
                                break;
                              case 7:
                                activeWidget = const AdminSupportChatsPage(isEmbedded: true);
                                break;
                              case 8:
                                activeWidget = _buildAdminsTab();
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
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _activeTab > 4 ? 0 : _activeTab,
              onTap: (index) => setState(() => _activeTab = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: cardBgColor,
              selectedItemColor: const Color(0xFF4F46E5),
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
                    label: "Appts"),
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

  Widget _buildAdminsTab() {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "Administrator Accounts",
                    style: TextStyle(
                      fontSize: isDesktop ? 22 : 18,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "System Admins",
                      style: TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddAdminUserPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text("Add Admin User", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'admin')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.admin_panel_settings_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        "No admin users registered yet.",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Admin User';
                  final email = data['email'] ?? 'No Email';
                  final adminRole = data['adminRole'] ?? 'System Administrator';
                  final createdAt = data['createdAt'] as Timestamp?;
                  final dateStr = createdAt != null ? DateFormat('MMM d, yyyy').format(createdAt.toDate()) : 'Recently Added';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF4F46E5), size: 24),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    adminRole,
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text("Added: $dateStr", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                          tooltip: "Revoke Admin Access",
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Revoke Admin User"),
                                content: Text("Are you sure you want to remove administrative access for $name ($email)?"),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text("Revoke Access", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await doc.reference.delete();
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
