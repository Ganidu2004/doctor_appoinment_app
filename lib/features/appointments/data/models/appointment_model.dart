import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appoinment_app/features/appointments/domain/entities/appointment_entity.dart';

class AppointmentModel extends AppointmentEntity {
  const AppointmentModel({
    required super.id,
    required super.doctorId,
    required super.patientUid,
    required super.date,
    required super.time,
    required super.status,
    required super.consultationFee,
    required super.hospitalCharges,
    required super.paymentId,
    required super.paymentMethod,
    required super.createdAt,
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
      'createdAt': Timestamp.fromDate(createdAt),
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
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  factory AppointmentModel.fromEntity(AppointmentEntity entity) {
    return AppointmentModel(
      id: entity.id,
      doctorId: entity.doctorId,
      patientUid: entity.patientUid,
      date: entity.date,
      time: entity.time,
      status: entity.status,
      consultationFee: entity.consultationFee,
      hospitalCharges: entity.hospitalCharges,
      paymentId: entity.paymentId,
      paymentMethod: entity.paymentMethod,
      createdAt: entity.createdAt,
    );
  }
}
