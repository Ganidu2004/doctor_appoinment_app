import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appoinment_app/features/patient/domain/entities/patient_entity.dart';

class PatientModel extends PatientEntity {
  const PatientModel({
    required super.uid,
    required super.firstName,
    required super.lastName,
    required super.name,
    required super.phone,
    required super.age,
    required super.gender,
    required super.address,
    required super.city,
    required super.nicNumber,
    required super.email,
    super.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'name': name,
      'phone': phone,
      'age': age,
      'gender': gender,
      'address': address,
      'city': city,
      'nicNumber': nicNumber,
      'email': email,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      uid: map['uid'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      age: map['age'] is int ? map['age'] : int.tryParse(map['age']?.toString() ?? '0') ?? 0,
      gender: map['gender'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      nicNumber: map['nicNumber'] ?? '',
      email: map['email'] ?? '',
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }

  factory PatientModel.fromEntity(PatientEntity entity) {
    return PatientModel(
      uid: entity.uid,
      firstName: entity.firstName,
      lastName: entity.lastName,
      name: entity.name,
      phone: entity.phone,
      age: entity.age,
      gender: entity.gender,
      address: entity.address,
      city: entity.city,
      nicNumber: entity.nicNumber,
      email: entity.email,
      createdAt: entity.createdAt,
    );
  }
}
