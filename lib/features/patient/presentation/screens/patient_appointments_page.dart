import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:appoinment_app/core/services/notification_services.dart';
import 'package:appoinment_app/core/services/schedule_cancellation_service.dart';
import 'package:intl/intl.dart';
import 'package:appoinment_app/features/patient/presentation/screens/find_doctor.dart';
import 'package:appoinment_app/features/patient/presentation/screens/patient_chat_page.dart';
import 'package:appoinment_app/features/patient/presentation/screens/home_page.dart';
import 'package:appoinment_app/features/appointments/presentation/screens/hospital_booking_pass_page.dart';

class PatientAppointmentsPage extends StatefulWidget {
  final bool showAppBar;
  const PatientAppointmentsPage({super.key, this.showAppBar = false});

  @override
  State<PatientAppointmentsPage> createState() => _PatientAppointmentsPageState();
}

class _PatientAppointmentsPageState extends State<PatientAppointmentsPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Booked', 'Completed', 'Cancelled'];

  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
        'status': 'Cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      try {
        await NotificationService().showNotification(
          id: 401,
          title: 'Appointment Cancelled',
          body: 'Your appointment was cancelled successfully.',
        );
      } catch (err) {
        debugPrint('Notification error: $err');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Appointment cancelled successfully.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to cancel appointment: $error')),
      );
    }
  }

  String _formatDoctorName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Dr. Doctor';
    var cleanName = name.trim();
    if (cleanName.toLowerCase().startsWith('dr.') || cleanName.toLowerCase().startsWith('dr ')) {
      cleanName = cleanName.substring(3).trim();
    }
    final words = cleanName.split(' ').where((w) => w.isNotEmpty).map((word) {
      if (word.length <= 1) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
    return 'Dr. $words';
  }

  String _formatStatusBadge(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('refund')) return 'Refunded';
    if (lower.contains('reschedule')) return 'Rescheduled';
    if (lower == 'booked' || lower == 'confirmed') return 'Confirmed';
    if (lower == 'completed') return 'Completed';
    if (lower == 'cancelled') return 'Cancelled';
    return status.isEmpty ? 'Booked' : status[0].toUpperCase() + status.substring(1);
  }

  IconData _statusIcon(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('refund')) return Icons.account_balance_wallet_rounded;
    if (lower.contains('reschedule')) return Icons.update_rounded;
    if (lower == 'booked' || lower == 'confirmed') return Icons.event_available_rounded;
    if (lower == 'completed') return Icons.check_circle_rounded;
    if (lower == 'cancelled') return Icons.cancel_rounded;
    return Icons.bookmark_border_rounded;
  }

  Color _statusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
      case 'confirmed':
        return const Color(0xFF0369A1);
      case 'completed':
        return const Color(0xFF15803D);
      case 'cancelled':
        return const Color(0xFFB91C1C);
      case 'refunded':
      case 'cancelled (refunded)':
        return const Color(0xFFB45309);
      default:
        return const Color(0xFF475569);
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
      case 'confirmed':
        return const Color(0xFFE0F2FE);
      case 'completed':
        return const Color(0xFFDCFCE7);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      case 'refunded':
      case 'cancelled (refunded)':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _statusBorderColor(String status) {
    switch (status.toLowerCase()) {
      case 'booked':
      case 'confirmed':
        return const Color(0xFFBAE6FD);
      case 'completed':
        return const Color(0xFFBBF7D0);
      case 'cancelled':
        return const Color(0xFFFCA5A5);
      case 'refunded':
      case 'cancelled (refunded)':
        return const Color(0xFFFDE68A);
      default:
        return const Color(0xFFE2E8F0);
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'LKR 0';
    final value = amount is num ? amount.toDouble() : double.tryParse(amount.toString()) ?? 0.0;
    return 'LKR ${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    )}';
  }

  bool _isDateExpired(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    try {
      final parsedDate = DateFormat("MMMM d, yyyy").parse(dateStr);
      return parsedDate.isBefore(todayStart);
    } catch (_) {
      try {
        final parsedDate = DateTime.parse(dateStr);
        return parsedDate.isBefore(todayStart);
      } catch (_) {
        return false;
      }
    }
  }

  void _showRescheduleDatePicker(BuildContext context, Map<String, dynamic> invData) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );

      if (pickedTime != null && context.mounted) {
        final formattedDate = DateFormat("MMMM d, yyyy").format(pickedDate);
        final formattedTime = pickedTime.format(context);

        final success = await ScheduleCancellationService().resolveInvoiceByReschedule(
          invoiceId: invData['id'] ?? '',
          appointmentId: invData['appointmentId'] ?? '',
          newDate: formattedDate,
          newTime: formattedTime,
        );

        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appointment successfully rescheduled to $formattedDate at $formattedTime!'),
              backgroundColor: const Color(0xFF0EA5E9),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showCancellationInvoiceModal(BuildContext context, String appointmentId, Map<String, dynamic> apptData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('invoices')
                .where('appointmentId', isEqualTo: appointmentId)
                .limit(1)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 250,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              Map<String, dynamic>? invData;
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                invData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                invData['id'] = snapshot.data!.docs.first.id;
              }

              final invNum = invData?['invoiceNumber'] ?? 'INV-CANCELLED';
              final actionType = invData?['actionType'] ?? 'Pending Patient Choice';
              final isPendingChoice = actionType == 'Pending Patient Choice';
              final remarks = invData?['remarks'] ?? 'Doctor schedule set to Off/Cancelled.';
              final fee = invData?['consultationFee'] ?? apptData['consultationFee'] ?? 0;
              final charges = invData?['hospitalCharges'] ?? apptData['hospitalCharges'] ?? 0;
              final total = invData?['totalAmount'] ?? ((fee is num ? fee.toDouble() : 0) + (charges is num ? charges.toDouble() : 0));
              final method = invData?['paymentMethod'] ?? apptData['paymentMethod'] ?? 'Online';

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Colors.redAccent, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cancellation Invoice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                              Text('No: $invNum', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isPendingChoice
                                ? Colors.orange.withValues(alpha: 0.15)
                                : (actionType == 'Refund' ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isPendingChoice
                                ? 'Action Required'
                                : (actionType == 'Refund' ? 'Refund Issued' : 'Rescheduled'),
                            style: TextStyle(
                              color: isPendingChoice
                                  ? Colors.orange.shade900
                                  : (actionType == 'Refund' ? Colors.green.shade800 : Colors.blue.shade800),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Doctor:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Dr. ${apptData['doctorName'] ?? 'Doctor'}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Original Date:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${apptData['date']} (${apptData['time']})',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Hospital:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  apptData['hospitalName'] ?? 'N/A',
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Payment Method:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$method',
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Financial Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Consultation Fee', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        Text(_formatCurrency(fee), style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hospital Service Charges', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        Text(_formatCurrency(charges), style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Invoice Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                        Text(_formatCurrency(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0EA5E9))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cancellation Reason / Note:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown)),
                          const SizedBox(height: 4),
                          Text(remarks, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // âš¡ Interactive Resolution Buttons (if Pending Patient Choice)
                    if (isPendingChoice && invData != null) ...[
                      const Text('Select Resolution Option:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () async {
                                Navigator.pop(context);
                                final success = await ScheduleCancellationService().resolveInvoiceByRefund(
                                  invoiceId: invData!['id'] ?? '',
                                  appointmentId: appointmentId,
                                );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Refund claimed successfully! Amount will be returned.'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.account_balance_wallet_rounded, size: 16),
                              label: const Text('Claim Refund', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0EA5E9),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _showRescheduleDatePicker(context, invData!);
                              },
                              icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                              label: const Text('Reschedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close Invoice', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Please sign in to view your appointments.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              iconTheme: const IconThemeData(color: Colors.black),
              title: const Text(
                'My Appointments',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Creative Filter Bar with Active Gradient
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;

                    IconData filterIcon;
                    switch (filter) {
                      case 'Booked':
                        filterIcon = Icons.calendar_today_rounded;
                        break;
                      case 'Completed':
                        filterIcon = Icons.check_circle_rounded;
                        break;
                      case 'Cancelled':
                        filterIcon = Icons.cancel_rounded;
                        break;
                      default:
                        filterIcon = Icons.view_headline_rounded;
                    }

                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : null,
                          color: isSelected ? null : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              filterIcon,
                              size: 15,
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              filter,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF334155),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
                  builder: (context, doctorsSnapshot) {
                    final Map<String, String> doctorImages = {};
                    if (doctorsSnapshot.hasData) {
                      for (var doc in doctorsSnapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final img = (data['profileImageUrl'] ?? data['imageUrl'] ?? data['profileImage'] ?? data['image'] ?? '').toString().trim();
                        if (img.isNotEmpty) {
                          doctorImages[doc.id] = img;
                          if (data['uid'] != null) doctorImages[data['uid'].toString()] = img;
                          if (data['doctorId'] != null) doctorImages[data['doctorId'].toString()] = img;
                          if (data['id'] != null) doctorImages[data['id'].toString()] = img;
                        }
                      }
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('appointments')
                          .where('patientUid', isEqualTo: user.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return _buildEmptyState();
                        }

                        var docs = snapshot.data!.docs;

                        // Apply filter
                        if (_selectedFilter != 'All') {
                          docs = docs.where((doc) {
                            final status = (doc.data() as Map<String, dynamic>)['status']?.toString() ?? '';
                            return status.toLowerCase() == _selectedFilter.toLowerCase();
                          }).toList();
                        }

                        if (docs.isEmpty) {
                          return _buildEmptyState();
                        }

                        final appointments = docs.toList()
                          ..sort((a, b) {
                            final aData = a.data() as Map<String, dynamic>;
                            final bData = b.data() as Map<String, dynamic>;
                            final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                            final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                            return bTime.compareTo(aTime);
                          });

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: appointments.length,
                          itemBuilder: (context, index) {
                            final doc = appointments[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final status = (data['status'] ?? 'Booked').toString();
                            final doctorId = (data['doctorId'] ?? '').toString();
                            final imageUrl = (data['doctorImage'] ?? data['profileImageUrl'] ?? data['doctorProfileImageUrl'] ?? doctorImages[doctorId] ?? '').toString().trim();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Stack(
                                  children: [
                                    // Left Status Accent Bar
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 5,
                                        color: _statusTextColor(status),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 5),
                                      child: Material(
                                        color: Colors.white,
                                        child: Theme(
                                          data: Theme.of(context).copyWith(
                                            dividerColor: Colors.transparent,
                                            iconTheme: const IconThemeData(color: Color(0xFF0EA5E9)),
                                          ),
                                          child: ExpansionTile(
                                            tilePadding: const EdgeInsets.all(16),
                                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                            iconColor: const Color(0xFF0EA5E9),
                                            collapsedIconColor: const Color(0xFF64748B),
                                            leading: _buildDoctorAvatar(imageUrl, _formatDoctorName(data['doctorName']?.toString())),
                                            title: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _formatDoctorName(data['doctorName']?.toString()),
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15.5,
                                                      color: Color(0xFF0F172A),
                                                      letterSpacing: -0.2,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF0F9FF),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        data['specialization'] ?? 'Specialist',
                                                        style: const TextStyle(
                                                          color: Color(0xFF0284C7),
                                                          fontSize: 11.5,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: _statusBgColor(status),
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: _statusBorderColor(status)),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(_statusIcon(status), size: 12, color: _statusTextColor(status)),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            _formatStatusBadge(status),
                                                            style: TextStyle(
                                                              color: _statusTextColor(status),
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                // Date, Time & Location Inner Box
                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF8FAFC),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF0EA5E9)),
                                                          const SizedBox(width: 5),
                                                          Text(
                                                            data['date'] ?? 'N/A',
                                                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold),
                                                          ),
                                                          const Spacer(),
                                                          const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF0EA5E9)),
                                                          const SizedBox(width: 5),
                                                          Text(
                                                            data['time'] ?? 'N/A',
                                                            style: const TextStyle(color: Color(0xFF0284C7), fontSize: 12, fontWeight: FontWeight.bold),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                                                          const SizedBox(width: 5),
                                                          Expanded(
                                                            child: Text(
                                                              data['hospitalName'] ?? 'Hospital / Clinic Center',
                                                              style: const TextStyle(color: Color(0xFF475569), fontSize: 11.5, fontWeight: FontWeight.w500),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            children: [
                                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                              const SizedBox(height: 14),
                                              _buildDetailRow(Icons.medical_information_outlined, 'Reason for Visit', data['reason']?.toString().isNotEmpty == true ? data['reason'] : 'General Consultation & Checkup'),
                                              const SizedBox(height: 10),
                                              _buildDetailRow(Icons.payments_outlined, 'Consultation Fee', _formatCurrency(data['consultationFee'])),
                                              const SizedBox(height: 16),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => HospitalBookingPassPage(
                                                              appointmentId: doc.id,
                                                              appointmentData: data,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                                        backgroundColor: const Color(0xFF0EA5E9),
                                                        foregroundColor: Colors.white,
                                                        elevation: 0,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                      ),
                                                      icon: const Icon(Icons.qr_code_2_rounded, size: 15),
                                                      label: const Text('Pass ðŸŽŸï¸', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: OutlinedButton.icon(
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => const PatientChatPage(),
                                                          ),
                                                        );
                                                      },
                                                      style: OutlinedButton.styleFrom(
                                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                                        side: const BorderSide(color: Color(0xFFBAE6FD)),
                                                        backgroundColor: const Color(0xFFF0F9FF),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                      ),
                                                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: Color(0xFF0284C7)),
                                                      label: const Text('Support', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 12)),
                                                    ),
                                                  ),
                                                  if ((status.toLowerCase().contains('cancelled') || status.toLowerCase().contains('rescheduled')) && !_isDateExpired(data['date'])) ...[
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: ElevatedButton.icon(
                                                        onPressed: () => _showCancellationInvoiceModal(context, doc.id, data),
                                                        style: ElevatedButton.styleFrom(
                                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                                          backgroundColor: const Color(0xFFFEF3C7),
                                                          foregroundColor: const Color(0xFFB45309),
                                                          elevation: 0,
                                                          side: const BorderSide(color: Color(0xFFFDE68A)),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                        ),
                                                        icon: const Icon(Icons.receipt_long_rounded, size: 15),
                                                        label: const Text('Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                      ),
                                                    ),
                                                  ],
                                                  if (status.toLowerCase() == 'completed') ...[
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: ElevatedButton.icon(
                                                        onPressed: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) => DoctorRatingDialog(
                                                              doctorId: doctorId,
                                                              doctorName: data['doctorName'] ?? 'Doctor',
                                                              patientUid: user.uid,
                                                            ),
                                                          );
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                                          backgroundColor: const Color(0xFFECFDF5),
                                                          foregroundColor: const Color(0xFF047857),
                                                          elevation: 0,
                                                          side: const BorderSide(color: Color(0xFFA7F3D0)),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                        ),
                                                        icon: const Icon(Icons.star_rounded, size: 15),
                                                        label: const Text('Rate Visit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                      ),
                                                    ),
                                                  ],
                                                  if (status.toLowerCase() != 'cancelled' && !status.toLowerCase().contains('cancelled') && status.toLowerCase() != 'completed') ...[
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: ElevatedButton.icon(
                                                        onPressed: () async {
                                                          final confirm = await showDialog<bool>(
                                                            context: context,
                                                            builder: (context) => AlertDialog(
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                              title: const Text('Cancel Appointment?', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                                              content: const Text('Are you sure you want to cancel this appointment? This action cannot be undone.', style: TextStyle(color: Color(0xFF475569))),
                                                              actions: [
                                                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep Appointment', style: TextStyle(color: Color(0xFF64748B)))),
                                                                ElevatedButton(
                                                                  onPressed: () => Navigator.pop(context, true),
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor: const Color(0xFFEF4444),
                                                                    elevation: 0,
                                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                                  ),
                                                                  child: const Text('Cancel It', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                          if (confirm == true) {
                                                            await _cancelAppointment(doc.id);
                                                          }
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                                          backgroundColor: const Color(0xFFFEE2E2),
                                                          foregroundColor: const Color(0xFFB91C1C),
                                                          elevation: 0,
                                                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                        ),
                                                        icon: const Icon(Icons.close_rounded, size: 15),
                                                        label: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorAvatar(String imageUrl, String doctorName) {
    final cleanUrl = imageUrl.trim();
    final String cleanDoctor = doctorName.replaceAll('Dr.', '').replaceAll('dr.', '').trim();
    final String initial = cleanDoctor.isNotEmpty ? cleanDoctor[0].toUpperCase() : 'D';

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE0F2FE),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 2),
      ),
      child: ClipOval(
        child: cleanUrl.isNotEmpty
            ? Image.network(
                cleanUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildAvatarFallback(initial);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0EA5E9)),
                    ),
                  );
                },
              )
            : _buildAvatarFallback(initial),
      ),
    );
  }

  Widget _buildAvatarFallback(String initial) {
    return Container(
      color: const Color(0xFFE0F2FE),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF0284C7),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0EA5E9)),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_outlined, size: 64, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Appointments Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'All'
                  ? 'Book a doctor to see your upcoming visits here.'
                  : 'You have no appointments with status "$_selectedFilter".',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FindDoctorScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Find a Doctor', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
