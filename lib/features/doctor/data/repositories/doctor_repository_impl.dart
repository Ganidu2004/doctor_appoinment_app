import 'package:appoinment_app/features/doctor/domain/entities/doctor_entity.dart';
import 'package:appoinment_app/features/doctor/domain/entities/schedule_entity.dart';
import 'package:appoinment_app/features/doctor/domain/repositories/doctor_repository.dart';
import 'package:appoinment_app/features/doctor/data/datasources/doctor_remote_datasource.dart';
import 'package:appoinment_app/features/doctor/data/models/doctor_model.dart';
import 'package:appoinment_app/features/doctor/data/models/schedule_model.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorRemoteDataSource remoteDataSource;

  DoctorRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DoctorEntity?> getDoctorProfile(String uid) {
    return remoteDataSource.getDoctorProfile(uid);
  }

  @override
  Future<void> createDoctorProfile(DoctorEntity doctor) {
    return remoteDataSource.createDoctorProfile(DoctorModel.fromEntity(doctor));
  }

  @override
  Future<void> updateDoctorProfile(DoctorEntity doctor) {
    return remoteDataSource.updateDoctorProfile(DoctorModel.fromEntity(doctor));
  }

  @override
  Stream<List<DoctorEntity>> getAllDoctors() {
    return remoteDataSource.getAllDoctors();
  }

  @override
  Future<void> updateDoctorSchedules(String doctorUid, List<ScheduleEntity> schedules) {
    final scheduleModels = schedules.map((s) => ScheduleModel.fromEntity(s)).toList();
    return remoteDataSource.updateDoctorSchedules(doctorUid, scheduleModels);
  }
}
