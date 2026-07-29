import 'package:appoinment_app/features/patient/domain/entities/patient_entity.dart';

abstract class PatientRepository {
  Future<PatientEntity?> getPatientProfile(String uid);
  Future<void> createPatientProfile(PatientEntity patient);
  Future<void> updatePatientProfile(PatientEntity patient);
  Stream<List<PatientEntity>> getAllPatients();
}
