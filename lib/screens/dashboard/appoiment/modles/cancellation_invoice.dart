// lib/screens/dashboard/appoiment/modles/cancellation_invoice.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CancellationInvoiceModel {
  final String id;
  final String invoiceNumber;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final String originalDate;
  final String time;
  final double totalAmount;
  final double consultationFee;
  final double hospitalCharges;
  final String actionType; // 'Refund' or 'Reschedule Credit'
  final String paymentMethod;
  final String remarks;
  final Timestamp issuedAt;

  CancellationInvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.originalDate,
    required this.time,
    required this.totalAmount,
    required this.consultationFee,
    required this.hospitalCharges,
    required this.actionType,
    required this.paymentMethod,
    required this.remarks,
    required this.issuedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'appointmentId': appointmentId,
      'patientId': patientId,
      'doctorId': doctorId,
      'originalDate': originalDate,
      'time': time,
      'totalAmount': totalAmount,
      'consultationFee': consultationFee,
      'hospitalCharges': hospitalCharges,
      'actionType': actionType,
      'paymentMethod': paymentMethod,
      'remarks': remarks,
      'issuedAt': issuedAt,
    };
  }

  factory CancellationInvoiceModel.fromMap(Map<String, dynamic> map, {String id = ''}) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return CancellationInvoiceModel(
      id: id.isNotEmpty ? id : (map['id'] ?? ''),
      invoiceNumber: map['invoiceNumber'] ?? '',
      appointmentId: map['appointmentId'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      originalDate: map['originalDate'] ?? '',
      time: map['time'] ?? '',
      totalAmount: parseDouble(map['totalAmount']),
      consultationFee: parseDouble(map['consultationFee']),
      hospitalCharges: parseDouble(map['hospitalCharges']),
      actionType: map['actionType'] ?? 'Refund',
      paymentMethod: map['paymentMethod'] ?? 'Online',
      remarks: map['remarks'] ?? 'Doctor schedule cancelled',
      issuedAt: map['issuedAt'] is Timestamp ? map['issuedAt'] as Timestamp : Timestamp.now(),
    );
  }
}
