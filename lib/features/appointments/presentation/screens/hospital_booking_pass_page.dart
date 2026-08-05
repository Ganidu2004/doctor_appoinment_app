import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HospitalBookingPassPage extends StatelessWidget {
  final String? appointmentId;
  final Map<String, dynamic>? appointmentData;

  const HospitalBookingPassPage({
    super.key,
    this.appointmentId,
    this.appointmentData,
  });

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

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'LKR 0';
    final value = amount is num ? amount.toDouble() : double.tryParse(amount.toString()) ?? 0.0;
    return 'LKR ${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (appointmentData != null) {
      return _buildPassContent(context, appointmentData!, appointmentId ?? '');
    }

    if (appointmentId != null && appointmentId!.isNotEmpty) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('appointments').doc(appointmentId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 0.5,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Hospital Verification Pass',
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                centerTitle: true,
              ),
              body: const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9))),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 0.5,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Hospital Verification Pass',
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                centerTitle: true,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
                    const SizedBox(height: 12),
                    Text('Appointment pass not found.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          return _buildPassContent(context, data, snapshot.data!.id);
        },
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Hospital Verification Pass',
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Center(child: Text('No booking information provided.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87))),
    );
  }

  Widget _buildPassContent(BuildContext context, Map<String, dynamic> data, String id) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String bookingNo = (data['bookingNo'] ?? 'DOC-${id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase()}').toString();
    final String doctorName = _formatDoctorName(data['doctorName']?.toString());
    final String specialization = (data['specialization'] ?? 'General Specialist').toString();
    final String hospitalName = (data['hospitalName'] ?? 'National Hospital / Medical Center').toString();
    final String patientName = (data['patientName'] ?? 'Patient').toString();
    final String date = (data['date'] ?? 'N/A').toString();
    final String time = (data['time'] ?? 'N/A').toString();
    final String status = (data['status'] ?? 'Booked').toString();
    final String paymentMethod = (data['paymentMethod'] ?? 'Card Payment').toString();
    final double consultationFee = data['consultationFee'] is num ? (data['consultationFee'] as num).toDouble() : 0.0;
    final double hospitalCharges = data['hospitalCharges'] is num ? (data['hospitalCharges'] as num).toDouble() : 0.0;
    final double totalAmount = consultationFee + hospitalCharges;

    String tokenDisplay = '#01';
    if (data['queueToken'] != null && data['queueToken'].toString().isNotEmpty) {
      tokenDisplay = data['queueToken'].toString();
    } else if (data['tokenNumber'] != null) {
      tokenDisplay = '#${data['tokenNumber'].toString().padLeft(2, '0')}';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Hospital Verification Pass',
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              'Ref: $bookingNo',
              style: const TextStyle(color: Color(0xFF0284C7), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Color(0xFF0EA5E9), size: 20),
            tooltip: 'Copy Reference',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: bookingNo));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Booking reference $bookingNo copied to clipboard!'),
                  backgroundColor: const Color(0xFF0EA5E9),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // Ticket Header Badge Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF1E40AF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_hospital_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'DOC TIME • OFFICIAL PASS',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'CONFIRMED',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Ticket Card Body
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Pass Reference & Token Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BOOKING NUMBER',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bookingNo,
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A), letterSpacing: 0.5),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD), width: 1.5),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'QUEUE TOKEN',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tokenDisplay,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scannable Barcode & QR Graphic Box
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Visual Simulated QR Code Box
                                Container(
                                  width: 72,
                                  height: 72,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: CustomPaint(
                                    painter: _QrCodePainter(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Visual Simulated Barcode Strip
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 48,
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFCBD5E1)),
                                        ),
                                        child: CustomPaint(
                                          painter: _BarcodePainter(),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'RECEPTION DESK SCANNER',
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'VERIFIED ✓',
                                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dashed Ticket Tear Divider
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                          ),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Flex(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                direction: Axis.horizontal,
                                children: List.generate(
                                  (constraints.constrainWidth() / 10).floor(),
                                  (_) => SizedBox(
                                    width: 5,
                                    height: 1.5,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Doctor Details Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'APPOINTMENT SPECIFICATION',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.person_rounded, color: Color(0xFF0284C7), size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doctorName,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      specialization,
                                      style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      hospitalName,
                                      style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Two Column Grid: Date & Time, Patient & Payment
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoItem(context, 'PATIENT NAME', patientName, Icons.account_circle_outlined),
                                ),
                                Container(width: 1, height: 36, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInfoItem(context, 'STATUS', status, Icons.verified_outlined, valueColor: isDark ? const Color(0xFF34D399) : const Color(0xFF047857)),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoItem(context, 'SCHEDULED DATE', date, Icons.calendar_month_outlined),
                                ),
                                Container(width: 1, height: 36, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInfoItem(context, 'TIME SLOT', time, Icons.access_time_outlined, valueColor: const Color(0xFF0284C7)),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoItem(context, 'PAYMENT METHOD', paymentMethod, Icons.payment_outlined),
                                ),
                                Container(width: 1, height: 36, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInfoItem(context, 'TOTAL AMOUNT', totalAmount > 0 ? _formatCurrency(totalAmount) : 'Paid', Icons.account_balance_wallet_outlined, valueColor: isDark ? Colors.white : const Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Hospital Entry Instructions Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Hospital Verification Protocol',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1. Arrive 15 minutes before your scheduled appointment slot.',
                              style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFFFEF3C7) : const Color(0xFF92400E), height: 1.35),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '2. Present this digital pass or booking reference to Counter #02 at OPD.',
                              style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFFFEF3C7) : const Color(0xFF92400E), height: 1.35),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '3. Carry a valid National ID (NIC) or Hospital Membership Card.',
                              style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFFFEF3C7) : const Color(0xFF92400E), height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Action Bar
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: 'Appointment Booking No: $bookingNo\nDoctor: $doctorName\nHospital: $hospitalName\nDate: $date at $time'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Hospital pass details copied to clipboard for sharing!'),
                              backgroundColor: Color(0xFF0EA5E9),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: Icon(Icons.share_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 18),
                        label: Text('Share Pass', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.home_rounded, color: Colors.white, size: 18),
                          label: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String title, String value, IconData icon, {Color? valueColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), letterSpacing: 0.3),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// Custom Painter for Visual QR Code Graphic
class _QrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    final double tileSize = size.width / 7;

    // Corner Position Detection Patterns
    canvas.drawRect(Rect.fromLTWH(0, 0, tileSize * 2, tileSize * 2), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - tileSize * 2, 0, tileSize * 2, tileSize * 2), paint);
    canvas.drawRect(Rect.fromLTWH(0, size.height - tileSize * 2, tileSize * 2, tileSize * 2), paint);

    // Inner Grid Bits
    canvas.drawRect(Rect.fromLTWH(tileSize * 3, tileSize, tileSize, tileSize), paint);
    canvas.drawRect(Rect.fromLTWH(tileSize * 5, tileSize * 2, tileSize, tileSize), paint);
    canvas.drawRect(Rect.fromLTWH(tileSize * 2, tileSize * 4, tileSize, tileSize), paint);
    canvas.drawRect(Rect.fromLTWH(tileSize * 4, tileSize * 3, tileSize * 2, tileSize), paint);
    canvas.drawRect(Rect.fromLTWH(tileSize * 3, tileSize * 5, tileSize, tileSize * 2), paint);
    canvas.drawRect(Rect.fromLTWH(tileSize * 5, tileSize * 5, tileSize, tileSize), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for Visual Barcode Graphic
class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    final double width = size.width;
    final double height = size.height;

    final List<double> barWidths = [3, 1, 4, 2, 1, 3, 5, 2, 1, 4, 2, 3, 1, 5, 2, 4, 1, 3];
    double currentX = 4;

    for (int i = 0; i < barWidths.length; i++) {
      if (currentX + barWidths[i] > width - 4) break;
      if (i % 2 == 0) {
        canvas.drawRect(Rect.fromLTWH(currentX, 0, barWidths[i], height), paint);
      }
      currentX += barWidths[i] + (i % 3 == 0 ? 3 : 2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
