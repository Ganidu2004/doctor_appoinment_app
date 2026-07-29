import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPaymentsPage extends StatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  State<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  bool _matchesSearch(Map<String, dynamic> data, String id) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    final patientName = data['patientName']?.toString().toLowerCase() ?? '';
    final bookingNo = (data['bookingNo'] ?? 'DOC-${id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase()}').toString().toLowerCase();
    return patientName.contains(query) || bookingNo.contains(query);
  }

  Widget _buildSummaryTab(List<DocumentSnapshot> docs, bool isHospital) {
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
        // Summary Header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isHospital 
                ? [const Color(0xFF10B981), const Color(0xFF047857)] 
                : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isHospital ? const Color(0xFF10B981) : const Color(0xFF3B82F6)).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isHospital ? Icons.local_hospital_rounded : Icons.medical_services_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Detailed List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: sortedEntries.length,
            itemBuilder: (context, index) {
              final entry = sortedEntries[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isHospital ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                      child: Icon(
                        isHospital ? Icons.domain_rounded : Icons.person_rounded,
                        color: isHospital ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Revenue share',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(entry.value),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
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

  Widget _buildPatientPaymentsTab(List<DocumentSnapshot> allDocs) {
    var docs = allDocs.where((doc) {
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
        // Search Input Box
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by patient or booking ref...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0EA5E9)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        
        Expanded(
          child: docs.isEmpty
            ? const Center(child: Text("No matching payments found."))
            : ListView.builder(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final patientName = data['patientName']?.toString() ?? 'Patient';
                  final date = data['date']?.toString() ?? 'N/A';
                  final time = data['time']?.toString() ?? 'N/A';
                  final consultationFee = data['consultationFee'] is num ? (data['consultationFee'] as num).toDouble() : 0.0;
                  final hospitalCharges = data['hospitalCharges'] is num ? (data['hospitalCharges'] as num).toDouble() : 0.0;
                  final totalAmount = consultationFee + hospitalCharges;
                  final bookingNo = (data['bookingNo'] ?? 'DOC-${doc.id.length >= 6 ? doc.id.substring(0, 6).toUpperCase() : doc.id.toUpperCase()}').toString();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                patientName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBAE6FD)),
                              ),
                              child: Text(
                                bookingNo,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text('$date • $time', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Consultation', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            Text(_formatCurrency(consultationFee), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Hospital Fee', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            Text(_formatCurrency(hospitalCharges), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Paid', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: const Text(
            'Revenue & Payments',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF0EA5E9),
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFF0EA5E9),
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Hospitals"),
              Tab(text: "Doctors"),
              Tab(text: "Patients"),
            ],
          ),
        ),
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No payments found."));
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
          ),
        ),
      ),
    );
  }
}
