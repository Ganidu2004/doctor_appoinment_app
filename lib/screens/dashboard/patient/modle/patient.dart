import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String name;
  final String phone;
  final int age;
  final String gender;
  final String address;
  final String city;
  final String nicNumber;
  final String email;
  final DateTime? createdAt;

  PatientModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.phone,
    required this.age,
    required this.gender,
    required this.address,
    required this.city,
    required this.nicNumber,
    required this.email,
    this.createdAt,
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
      'createdAt': createdAt ?? FieldValue.serverTimestamp(), 
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
}