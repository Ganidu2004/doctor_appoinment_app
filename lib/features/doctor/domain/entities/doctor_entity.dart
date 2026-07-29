import 'schedule_entity.dart';

class DoctorEntity {
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
  final List<ScheduleEntity> schedules;

  const DoctorEntity({
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
}
