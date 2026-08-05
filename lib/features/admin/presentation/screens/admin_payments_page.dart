import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminPaymentsPage extends StatefulWidget {
  final bool isEmbedded;
  const AdminPaymentsPage({super.key, this.isEmbedded = false});

  @override
  State<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _filterByMonth = true;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'LKR 0';
    final value = amount is num ? amount.toDouble() : double.tryParse(amount.toString()) ?? 0.0;
    return 'LKR ${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    )}';
  }

  DateTime? _parseAppointmentDate(Map<String, dynamic> data) {
    if (data['createdAt'] is Timestamp) {
      return (data['createdAt'] as Timestamp).toDate();
    }
    final dateStr = (data['date'] ?? data['appointmentDate'] ?? '').toString();
    if (dateStr.isEmpty) return null;
    try {
      return DateFormat("MMMM d, yyyy").parse(dateStr);
    } catch (_) {}
    try {
      return DateFormat("yyyy-MM-dd").parse(dateStr);
    } catch (_) {}
    return DateTime.tryParse(dateStr);
  }

  bool _isSameMonthYear(DateTime date, DateTime selected) {
    return date.year == selected.year && date.month == selected.month;
  }

  List<DocumentSnapshot> _filterDocsByMonth(List<DocumentSnapshot> allDocs) {
    if (!_filterByMonth) return allDocs;
    return allDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final apptDate = _parseAppointmentDate(data);
      if (apptDate == null) return true;
      return _isSameMonthYear(apptDate, _selectedMonth);
    }).toList();
  }

  bool _matchesSearch(Map<String, dynamic> data, String id) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    final patientName = data['patientName']?.toString().toLowerCase() ?? '';
    final bookingNo = (data['bookingNo'] ?? 'DOC-${id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase()}').toString().toLowerCase();
    return patientName.contains(query) || bookingNo.contains(query);
  }

  Widget _buildMonthSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthFormat = DateFormat("MMMM yyyy");
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 450;
          if (isNarrow) {
            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF4F46E5)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "BILLING PERIOD",
                            style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _filterByMonth ? monthFormat.format(_selectedMonth) : "All Time (All Months)",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_filterByMonth)
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left_rounded, size: 18, color: isDark ? Colors.white : Colors.black87),
                              onPressed: () {
                                setState(() {
                                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                                });
                              },
                              tooltip: "Previous Month",
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            Container(width: 1, height: 16, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            IconButton(
                              icon: Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? Colors.white : Colors.black87),
                              onPressed: () {
                                setState(() {
                                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                                });
                              },
                              tooltip: "Next Month",
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ],
                        ),
                      ),
                    PopupMenuButton<String>(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      onSelected: (val) {
                        if (val == 'ALL') {
                          setState(() => _filterByMonth = false);
                        } else if (val == 'CURRENT') {
                          setState(() {
                            _filterByMonth = true;
                            _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _filterByMonth ? Icons.filter_alt_rounded : Icons.filter_alt_off_rounded,
                              size: 14,
                              color: const Color(0xFF4F46E5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _filterByMonth ? "Month Filter" : "All Time",
                              style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF4F46E5)),
                          ],
                        ),
                      ),
                      itemBuilder: (ctx) => [
                        PopupMenuItem(value: 'CURRENT', child: Text("Current Month Filter", style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
                        PopupMenuItem(value: 'ALL', child: Text("Show All Months (All Time)", style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
                      ],
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF4F46E5)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "BILLING PERIOD",
                        style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _filterByMonth ? monthFormat.format(_selectedMonth) : "All Time (All Months)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  if (_filterByMonth)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left_rounded, size: 18, color: isDark ? Colors.white : Colors.black87),
                            onPressed: () {
                              setState(() {
                                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                              });
                            },
                            tooltip: "Previous Month",
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          Container(width: 1, height: 16, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          IconButton(
                            icon: Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? Colors.white : Colors.black87),
                            onPressed: () {
                              setState(() {
                                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                              });
                            },
                            tooltip: "Next Month",
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuButton<String>(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    onSelected: (val) {
                      if (val == 'ALL') {
                        setState(() => _filterByMonth = false);
                      } else if (val == 'CURRENT') {
                        setState(() {
                          _filterByMonth = true;
                          _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _filterByMonth ? Icons.filter_alt_rounded : Icons.filter_alt_off_rounded,
                            size: 14,
                            color: const Color(0xFF4F46E5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _filterByMonth ? "Month Filter" : "All Time",
                            style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF4F46E5)),
                        ],
                      ),
                    ),
                    itemBuilder: (ctx) => [
                      PopupMenuItem(value: 'CURRENT', child: Text("Current Month Filter", style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
                      PopupMenuItem(value: 'ALL', child: Text("Show All Months (All Time)", style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryTab(List<DocumentSnapshot> rawDocs, bool isHospital) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final docs = _filterDocsByMonth(rawDocs);

    // Aggregate data
    Map<String, double> totals = {};
    double grandTotal = 0.0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (isHospital) {
        final hospitalName = data['hospital']?.toString() ?? data['hospitalName']?.toString() ?? 'Unknown Hospital';
        final charge = data['hospitalCharges'] is num ? (data['hospitalCharges'] as num).toDouble() : 0.0;
        totals[hospitalName] = (totals[hospitalName] ?? 0.0) + charge;
        grandTotal += charge;
      } else {
        final doctorName = data['doctorName']?.toString() ?? 'Unknown Doctor';
        final charge = data['consultationFee'] is num ? (data['consultationFee'] as num).toDouble() : 0.0;
        totals[doctorName] = (totals[doctorName] ?? 0.0) + charge;
        grandTotal += charge;
      }
    }

    final sortedEntries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        _buildMonthSelector(),
        // Hero Financial Revenue Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isHospital 
                ? [const Color(0xFF059669), const Color(0xFF10B981), const Color(0xFF0D9488)] 
                : [const Color(0xFF4F46E5), const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isHospital ? const Color(0xFF10B981) : const Color(0xFF4F46E5)).withValues(alpha: 0.35),
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
                  isHospital ? Icons.local_hospital_rounded : Icons.medical_services_rounded,
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
                      isHospital ? "HOSPITAL REVENUE SHARES" : "DOCTOR CONSULTATION FEES",
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
                    isHospital ? "Total Hospital Revenue" : "Total Doctor Revenue",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(grandTotal),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Detailed List / Creative Empty State
        Expanded(
          child: sortedEntries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No payments recorded for ${DateFormat('MMMM yyyy').format(_selectedMonth)}.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _filterByMonth = false);
                          },
                          icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                          label: const Text("Show All Time Ledger"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4F46E5),
                            side: const BorderSide(color: Color(0xFF4F46E5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sortedEntries.length,
                  itemBuilder: (context, index) {
                    final entry = sortedEntries[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isHospital ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5)) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              isHospital ? Icons.domain_rounded : Icons.person_rounded,
                              color: isHospital ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isHospital ? 'Hospital Facility Revenue Share' : 'Specialist Consultation Earnings',
                                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatCurrency(entry.value),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isDark ? Colors.white : const Color(0xFF0F172A)),
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

  Widget _buildPatientPaymentsTab(List<DocumentSnapshot> rawDocs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredMonthDocs = _filterDocsByMonth(rawDocs);

    var docs = filteredMonthDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return _matchesSearch(data, doc.id);
    }).toList();

    // Sort newest first
    docs.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return Column(
      children: [
        _buildMonthSelector(),
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Search patient name or booking no...',
              hintStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey),
              prefixIcon: Icon(Icons.search, color: isDark ? const Color(0xFF94A3B8) : Colors.grey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 18, color: isDark ? Colors.white : Colors.black87),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF0EA5E9)),
              ),
            ),
          ),
        ),
        Expanded(
          child: docs.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? 'No matching patient payments found.'
                        : 'No patient payments recorded for ${DateFormat('MMMM yyyy').format(_selectedMonth)}.',
                    style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final patientName = data['patientName'] ?? 'Unknown Patient';
                    final doctorName = data['doctorName'] ?? 'Unknown Doctor';
                    final hospital = data['hospital'] ?? data['hospitalName'] ?? '';
                    final totalAmount = data['totalAmount'] ?? data['fee'] ?? 0;
                    final consultationFee = data['consultationFee'] ?? 0;
                    final hospitalCharges = data['hospitalCharges'] ?? 0;
                    final dateStr = data['date'] ?? '';
                    final timeStr = data['time'] ?? '';
                    final bookingNo = data['bookingNo'] ?? 'DOC-${doc.id.length >= 6 ? doc.id.substring(0, 6).toUpperCase() : doc.id.toUpperCase()}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  bookingNo,
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                '$dateStr $timeStr'.trim(),
                                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                radius: 20,
                                child: Icon(Icons.person, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patientName,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Dr. $doctorName${hospital.toString().isNotEmpty ? ' • $hospital' : ''}',
                                      style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Doctor Fee: ${_formatCurrency(consultationFee)}',
                                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                              ),
                              Text(
                                'Hospital Charge: ${_formatCurrency(hospitalCharges)}',
                                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Paid', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                              Text(_formatCurrency(totalAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0EA5E9))),
                            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bodyContent = StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No payments found.", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)));
        }

        final docs = snapshot.data!.docs;

        return TabBarView(
          children: [
            _buildSummaryTab(docs, true),
            _buildSummaryTab(docs, false),
            _buildPatientPaymentsTab(docs),
          ],
        );
      },
    );

    if (widget.isEmbedded) {
      return DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Material(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: TabBar(
                labelColor: const Color(0xFF0EA5E9),
                unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : Colors.black54,
                indicatorColor: const Color(0xFF0EA5E9),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "Hospitals"),
                  Tab(text: "Doctors"),
                  Tab(text: "Patients"),
                ],
              ),
            ),
            Expanded(child: bodyContent),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0.5,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
          title: Text(
            'Revenue & Payments',
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          bottom: TabBar(
            labelColor: const Color(0xFF0EA5E9),
            unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : Colors.black54,
            indicatorColor: const Color(0xFF0EA5E9),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Hospitals"),
              Tab(text: "Doctors"),
              Tab(text: "Patients"),
            ],
          ),
        ),
        body: SafeArea(child: bodyContent),
      ),
    );
  }
}
