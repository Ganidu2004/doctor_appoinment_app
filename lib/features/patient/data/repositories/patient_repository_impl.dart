import 'package:appoinment_app/features/patient/domain/entities/patient_entity.dart';
import 'package:appoinment_app/features/patient/domain/repositories/patient_repository.dart';
import 'package:appoinment_app/features/patient/data/datasources/patient_remote_datasource.dart';
import 'package:appoinment_app/features/patient/data/models/patient_model.dart';

class PatientRepositoryImpl implements PatientRepository {
  final PatientRemoteDataSource remoteDataSource;

  PatientRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PatientEntity?> getPatientProfile(String uid) {
    return remoteDataSource.getPatientProfile(uid);
  }

  @override
  Future<void> createPatientProfile(PatientEntity patient) {
    return remoteDataSource.createPatientProfile(PatientModel.fromEntity(patient));
  }

  @override
  Future<void> updatePatientProfile(PatientEntity patient) {
    return remoteDataSource.updatePatientProfile(PatientModel.fromEntity(patient));
  }

  @override
  Stream<List<PatientEntity>> getAllPatients() {
    return remoteDataSource.getAllPatients();
  }
}
