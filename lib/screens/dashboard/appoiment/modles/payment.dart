import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final double amount;
  final double hospitalCharges;
  final String paymentMethod;
  final String paymentStatus;
  final Timestamp paymentDate;

  PaymentModel({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.amount,
    required this.hospitalCharges,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentDate,
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
      'paymentDate': paymentDate,
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
      paymentDate: map['paymentDate'] is Timestamp ? map['paymentDate'] as Timestamp : Timestamp.now(),
    );
  }
}
