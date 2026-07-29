import 'package:appoinment_app/core/usecase/usecase.dart';
import 'package:appoinment_app/features/doctor/domain/entities/doctor_entity.dart';
import 'package:appoinment_app/features/doctor/domain/repositories/doctor_repository.dart';

class GetDoctorProfileUseCase implements UseCase<DoctorEntity?, String> {
  final DoctorRepository repository;
  GetDoctorProfileUseCase(this.repository);

  @override
  Future<DoctorEntity?> call(String uid) {
    return repository.getDoctorProfile(uid);
  }
}
