import 'package:flutter/material.dart';

class AppointmentReceiptModal {
  static String _formatName(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty) return 'Patient';
    final words = rawName.trim().split(' ').where((w) => w.isNotEmpty).map((word) {
      if (word.length <= 1) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
    return words;
  }

  static String _formatCurrency(dynamic amount) {
    if (amount == null) return 'LKR 0';
    final value = amount is num ? amount.toDouble() : double.tryParse(amount.toString()) ?? 0.0;
    return 'LKR ${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    )}';
  }

  static Widget _buildReceiptRow(BuildContext context, String label, String value, {bool isBold = false, Color? valueColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isBold ? 14 : 12.5,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ),
      ],
    );
  }

  static void show(BuildContext context, Map<String, dynamic> data, String id) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final patientName = _formatName(data['patientName']?.toString());
    final date = data['date']?.toString() ?? 'N/A';
    final time = data['time']?.toString() ?? 'N/A';
    final status = (data['status'] ?? 'Completed').toString();
    final hospitalName = data['hospitalName']?.toString() ?? 'Medical Center';
    final consultationFee = data['consultationFee'] is num ? (data['consultationFee'] as num).toDouble() : 0.0;
    final hospitalCharges = data['hospitalCharges'] is num ? (data['hospitalCharges'] as num).toDouble() : 0.0;
    final totalAmount = consultationFee + hospitalCharges;
    final bookingNo = (data['bookingNo'] ?? 'DOC-${id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase()}').toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: Color(0xFF0EA5E9), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Appointment Summary',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD)),
                    ),
                    child: Text(
                      bookingNo,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow(context, 'Patient Name', patientName),
                    Divider(height: 16, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    _buildReceiptRow(context, 'Hospital / Venue', hospitalName),
                    Divider(height: 16, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    _buildReceiptRow(context, 'Scheduled Date', '$date at $time'),
                    Divider(height: 16, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    _buildReceiptRow(
                      context,
                      'Status',
                      status.toUpperCase(),
                      valueColor: status.toLowerCase() == 'completed'
                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                          : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C)),
                    ),
                    Divider(height: 16, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    _buildReceiptRow(context, 'Consultation Fee', _formatCurrency(consultationFee)),
                    Divider(height: 16, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    _buildReceiptRow(context, 'Hospital Facility Fee', _formatCurrency(hospitalCharges)),
                    Divider(height: 20, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    _buildReceiptRow(context, 'Total Amount', _formatCurrency(totalAmount), isBold: true, valueColor: const Color(0xFF0EA5E9)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF0EA5E9) : const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
