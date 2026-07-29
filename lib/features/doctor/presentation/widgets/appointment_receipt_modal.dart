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

  static Widget _buildReceiptRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isBold ? 14 : 12.5,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  static void show(BuildContext context, Map<String, dynamic> data, String id) {
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, color: Color(0xFF0EA5E9), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Appointment Summary',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Text(
                      bookingNo,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow('Patient Name', patientName),
                    const Divider(height: 16, color: Color(0xFFE2E8F0)),
                    _buildReceiptRow('Hospital / Venue', hospitalName),
                    const Divider(height: 16, color: Color(0xFFE2E8F0)),
                    _buildReceiptRow('Scheduled Date', '$date at $time'),
                    const Divider(height: 16, color: Color(0xFFE2E8F0)),
                    _buildReceiptRow('Status', status.toUpperCase(), valueColor: status.toLowerCase() == 'completed' ? const Color(0xFF047857) : const Color(0xFFB91C1C)),
                    const Divider(height: 16, color: Color(0xFFE2E8F0)),
                    _buildReceiptRow('Consultation Fee', _formatCurrency(consultationFee)),
                    const Divider(height: 16, color: Color(0xFFE2E8F0)),
                    _buildReceiptRow('Hospital Facility Fee', _formatCurrency(hospitalCharges)),
                    const Divider(height: 20, color: Color(0xFFCBD5E1)),
                    _buildReceiptRow('Total Amount', _formatCurrency(totalAmount), isBold: true, valueColor: const Color(0xFF0EA5E9)),
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
                    backgroundColor: const Color(0xFF0F172A),
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
