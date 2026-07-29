import 'package:appoinment_app/features/doctor/domain/entities/doctor_entity.dart';
import 'package:appoinment_app/features/doctor/domain/entities/schedule_entity.dart';

abstract class DoctorRepository {
  Future<DoctorEntity?> getDoctorProfile(String uid);
  Future<void> createDoctorProfile(DoctorEntity doctor);
  Future<void> updateDoctorProfile(DoctorEntity doctor);
  Stream<List<DoctorEntity>> getAllDoctors();
  Future<void> updateDoctorSchedules(String doctorUid, List<ScheduleEntity> schedules);
}
