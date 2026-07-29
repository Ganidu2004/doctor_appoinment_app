import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appoinment_app/features/appointments/domain/entities/cancellation_invoice_entity.dart';

class CancellationInvoiceModel extends CancellationInvoiceEntity {
  const CancellationInvoiceModel({
    required super.id,
    required super.invoiceNumber,
    required super.appointmentId,
    required super.patientId,
    required super.doctorId,
    required super.originalDate,
    required super.time,
    required super.totalAmount,
    required super.consultationFee,
    required super.hospitalCharges,
    required super.actionType,
    required super.paymentMethod,
    required super.remarks,
    required super.issuedAt,
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
      'issuedAt': Timestamp.fromDate(issuedAt),
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
      issuedAt: map['issuedAt'] is Timestamp 
          ? (map['issuedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  factory CancellationInvoiceModel.fromEntity(CancellationInvoiceEntity entity) {
    return CancellationInvoiceModel(
      id: entity.id,
      invoiceNumber: entity.invoiceNumber,
      appointmentId: entity.appointmentId,
      patientId: entity.patientId,
      doctorId: entity.doctorId,
      originalDate: entity.originalDate,
      time: entity.time,
      totalAmount: entity.totalAmount,
      consultationFee: entity.consultationFee,
      hospitalCharges: entity.hospitalCharges,
      actionType: entity.actionType,
      paymentMethod: entity.paymentMethod,
      remarks: entity.remarks,
      issuedAt: entity.issuedAt,
    );
  }
}
