import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:appoinment_app/features/doctor/presentation/widgets/appointment_receipt_modal.dart';
import 'package:flutter/material.dart';

class DoctorAppointmentHistoryPage extends StatefulWidget {
  const DoctorAppointmentHistoryPage({super.key});

  @override
  State<DoctorAppointmentHistoryPage> createState() => _DoctorAppointmentHistoryPageState();
}

class _DoctorAppointmentHistoryPageState extends State<DoctorAppointmentHistoryPage> {
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

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'LKR 0';
    final value = amount is num ? amount.toDouble() : double.tryParse(amount.toString()) ?? 0.0;
    return 'LKR ${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    )}';
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    final patientName = data['patientName']?.toString().toLowerCase() ?? '';
    final hospitalName = data['hospitalName']?.toString().toLowerCase() ?? '';
    final status = data['status']?.toString().toLowerCase() ?? '';
    final notes = (data['notes'] ?? data['reason'] ?? data['description'] ?? '').toString().toLowerCase();
    return patientName.contains(query) || hospitalName.contains(query) || status.contains(query) || notes.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view appointment history.'));
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
                    hintText: 'Search history by patient, date, hospital...',
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
                  children: ['All', 'Completed', 'Cancelled'].map((filter) {
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
                          filter == 'All' ? 'All History' : filter,
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

              // Stream Builder Appointment History List
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
                      return _buildEmptyHistoryState();
                    }

                    var docs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _matchesSearch(data);
                    }).toList();

                    // Apply filter
                    if (_selectedFilter != 'All') {
                      docs = docs.where((doc) {
                        final status = (doc.data() as Map<String, dynamic>)['status']?.toString().toLowerCase() ?? '';
                        return status.contains(_selectedFilter.toLowerCase());
                      }).toList();
                    }

                    if (docs.isEmpty) {
                      return _buildEmptyHistoryState();
                    }

                    // Sort newest first
                    docs.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                      final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                      return bTime.compareTo(aTime);
                    });

                    return ListView.builder(
                      itemCount: docs.length,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final patientName = _formatName(data['patientName']?.toString());
                        final date = data['date']?.toString() ?? 'TBD';
                        final time = data['time']?.toString() ?? 'TBD';
                        final status = (data['status'] ?? 'Completed').toString();
                        final hospitalName = (data['hospitalName'] ?? 'Medical Center').toString();
                        final consultationFee = data['consultationFee'] is num ? (data['consultationFee'] as num).toDouble() : 0.0;

                        final bool isCompleted = status.toLowerCase().contains('complet');
                        final bool isCancelled = status.toLowerCase().contains('cancel');

                        Color statusColor = isCompleted
                            ? const Color(0xFF047857)
                            : isCancelled
                                ? const Color(0xFFB91C1C)
                                : const Color(0xFFB45309);

                        Color statusBg = isCompleted
                            ? const Color(0xFFECFDF5)
                            : isCancelled
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFFFFBEB);

                        Color statusBorder = isCompleted
                            ? const Color(0xFFA7F3D0)
                            : isCancelled
                                ? const Color(0xFFFECACA)
                                : const Color(0xFFFDE68A);

                        final String initial = patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P';

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
                                // Left Status Accent Indicator
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 5,
                                    color: statusColor,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE0F2FE),
                                              border: Border.all(color: isDark ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD), width: 1.5),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              initial,
                                              style: TextStyle(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 18),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  patientName,
                                                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  hospitalName,
                                                  style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF0F172A) : statusBg,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: isDark ? statusColor : statusBorder),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Scheduled Slot & Fee Surface
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF0EA5E9)),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '$date • $time',
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              _formatCurrency(consultationFee),
                                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Action Buttons Row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () => AppointmentReceiptModal.show(context, data, doc.id),
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            icon: Icon(Icons.receipt_long_rounded, size: 15, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                                            label: Text('Receipt', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 12)),
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
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
              child: const Icon(Icons.history_rounded, size: 48, color: Color(0xFF0EA5E9)),
            ),
            const SizedBox(height: 16),
            Text(
              'No Appointment History Found',
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Your past completed and processed consultations will be archived here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
