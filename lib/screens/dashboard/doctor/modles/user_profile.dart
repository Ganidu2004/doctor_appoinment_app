// lib/models/doctor_model.dart

import 'package:appoinment_app/screens/dashboard/doctor/modles/shedul.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

class DoctorModel {
  final String uid;
  final String name;
  final String gender; 
  final String specialization;
  final String phone;
  final String personalPhone;
  final int experience;
  final List<String> hospitalPhones;
  final List<Map<String, dynamic>> hospitalsList; 
  final String profileImageUrl;
  final List<String> qualifications;
  final String aboutMe;
  final DateTime createdAt;
  final List<ScheduleModel> schedules; 

  DoctorModel({
    required this.uid,
    required this.name,
    required this.gender, 
    required this.specialization,
    required this.phone,
    required this.personalPhone,
    required this.experience,
    required this.hospitalPhones,
    required this.hospitalsList,
    required this.profileImageUrl,
    required this.qualifications,
    required this.aboutMe,
    required this.createdAt,
    required this.schedules,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'gender': gender, 
      'specialization': specialization,
      'phone': phone,
      'personalPhone': personalPhone,
      'experience': experience,
      'hospitalPhones': hospitalPhones,
      'hospitalsList': hospitalsList, 
      'profileImageUrl': profileImageUrl,
      'qualifications': qualifications,
      'aboutMe': aboutMe,
      'createdAt': Timestamp.fromDate(createdAt),
      'schedules': schedules.map((x) => x.toMap()).toList(), 
    };
  }

  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        parsedDate = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        parsedDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
      }
    }

    return DoctorModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      gender: map['gender'] ?? '',
      specialization: map['specialization'] ?? '',
      phone: map['phone'] ?? '',
      personalPhone: map['personalPhone'] ?? '',
      experience: int.tryParse(map['experience']?.toString() ?? '0') ?? 0, 
      
      hospitalPhones: map['hospitalPhones'] is List
          ? List<String>.from((map['hospitalPhones'] as List).map((e) => e.toString()))
          : [],
          
      hospitalsList: map['hospitalsList'] is List
          ? List<Map<String, dynamic>>.from(
              (map['hospitalsList'] as List).map(
                (item) {
                  final hospitalMap = Map<String, dynamic>.from(item as Map);
                  return {
                    'hospitalName': hospitalMap['hospitalName'] ?? 'Unknown Hospital',
                    'hospitalDistrict': hospitalMap['hospitalDistrict'] ?? '', 
                    'hospitalAddresses': hospitalMap['hospitalAddresses'] is List
                        ? List<String>.from((hospitalMap['hospitalAddresses'] as List).map((e) => e.toString()))
                        : <String>[],
                    'hospitalPhone': hospitalMap['hospitalPhone'] ?? hospitalMap['hospitalPhoneNum'] ?? '',
                  };
                },
              ),
            )
          : [],
          
      profileImageUrl: map['profileImageUrl'] ?? map['imageUrl'] ?? '',
      
      qualifications: map['qualifications'] is List
          ? List<String>.from((map['qualifications'] as List).map((e) => e.toString()))
          : [],
          
      aboutMe: map['aboutMe'] ?? '',
      createdAt: parsedDate,
      
      schedules: map['schedules'] is List
          ? List<ScheduleModel>.from(
              (map['schedules'] as List).map(
                (x) => ScheduleModel.fromMap(Map<String, dynamic>.from(x as Map)),
              ),
            )
          : [],
    );
  }
}