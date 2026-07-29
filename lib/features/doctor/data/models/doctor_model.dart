import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appoinment_app/features/doctor/domain/entities/doctor_entity.dart';
import 'package:appoinment_app/features/doctor/data/models/schedule_model.dart';

class DoctorModel extends DoctorEntity {
  const DoctorModel({
    required super.uid,
    required super.name,
    required super.gender,
    required super.specialization,
    required super.phone,
    required super.personalPhone,
    required super.experience,
    required super.hospitalPhones,
    required super.hospitalsList,
    required super.profileImageUrl,
    required super.qualifications,
    required super.aboutMe,
    required super.createdAt,
    required super.schedules,
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
      'schedules': schedules.map((x) => ScheduleModel.fromEntity(x).toMap()).toList(),
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

  factory DoctorModel.fromEntity(DoctorEntity entity) {
    return DoctorModel(
      uid: entity.uid,
      name: entity.name,
      gender: entity.gender,
      specialization: entity.specialization,
      phone: entity.phone,
      personalPhone: entity.personalPhone,
      experience: entity.experience,
      hospitalPhones: entity.hospitalPhones,
      hospitalsList: entity.hospitalsList,
      profileImageUrl: entity.profileImageUrl,
      qualifications: entity.qualifications,
      aboutMe: entity.aboutMe,
      createdAt: entity.createdAt,
      schedules: entity.schedules.map((s) => ScheduleModel.fromEntity(s)).toList(),
    );
  }
}
