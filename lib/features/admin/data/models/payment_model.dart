import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appoinment_app/features/admin/domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.appointmentId,
    required super.patientId,
    required super.doctorId,
    required super.amount,
    required super.hospitalCharges,
    required super.paymentMethod,
    required super.paymentStatus,
    required super.paymentDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'patientId': patientId,
      'doctorId': doctorId,
      'amount': amount,
      'hospitalCharges': hospitalCharges,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return PaymentModel(
      id: id,
      appointmentId: map['appointmentId'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      amount: (map['amount'] is num ? (map['amount'] as num).toDouble() : double.tryParse(map['amount']?.toString() ?? '0') ?? 0),
      hospitalCharges: (map['hospitalCharges'] is num ? (map['hospitalCharges'] as num).toDouble() : double.tryParse(map['hospitalCharges']?.toString() ?? '0') ?? 0),
      paymentMethod: map['paymentMethod'] ?? '',
      paymentStatus: map['paymentStatus'] ?? '',
      paymentDate: map['paymentDate'] is Timestamp 
          ? (map['paymentDate'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  factory PaymentModel.fromEntity(PaymentEntity entity) {
    return PaymentModel(
      id: entity.id,
      appointmentId: entity.appointmentId,
      patientId: entity.patientId,
      doctorId: entity.doctorId,
      amount: entity.amount,
      hospitalCharges: entity.hospitalCharges,
      paymentMethod: entity.paymentMethod,
      paymentStatus: entity.paymentStatus,
      paymentDate: entity.paymentDate,
    );
  }
}
