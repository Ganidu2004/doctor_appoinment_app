import 'package:appoinment_app/core/usecase/usecase.dart';
import 'package:appoinment_app/features/patient/domain/entities/patient_entity.dart';
import 'package:appoinment_app/features/patient/domain/repositories/patient_repository.dart';

class GetPatientProfileUseCase implements UseCase<PatientEntity?, String> {
  final PatientRepository repository;
  GetPatientProfileUseCase(this.repository);

  @override
  Future<PatientEntity?> call(String uid) {
    return repository.getPatientProfile(uid);
  }
}
