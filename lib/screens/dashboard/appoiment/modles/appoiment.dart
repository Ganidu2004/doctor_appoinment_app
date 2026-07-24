import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String doctorId;
  final String patientUid;
  final String date; // yyyy-MM-dd
  final String time; // hh:mm a
  final String status;
  final double consultationFee;
  final double hospitalCharges;
  final String paymentId;
  final String paymentMethod;
  final Timestamp createdAt;

  AppointmentModel({
    required this.id,
    required this.doctorId,
    required this.patientUid,
    required this.date,
    required this.time,
    required this.status,
    required this.consultationFee,
    required this.hospitalCharges,
    required this.paymentId,
    required this.paymentMethod,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'patientUid': patientUid,
      'date': date,
      'time': time,
      'status': status,
      'consultationFee': consultationFee,
      'hospitalCharges': hospitalCharges,
      'paymentId': paymentId,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt,
    };
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map, {String id = ''}) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return AppointmentModel(
      id: id,
      doctorId: map['doctorId'] ?? '',
      patientUid: map['patientUid'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      status: map['status'] ?? 'Booked',
      consultationFee: parseDouble(map['consultationFee']),
      hospitalCharges: parseDouble(map['hospitalCharges']),
      paymentId: map['paymentId'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
}
