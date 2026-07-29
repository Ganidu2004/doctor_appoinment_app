import 'package:appoinment_app/core/usecase/usecase.dart';
import 'package:appoinment_app/features/appointments/domain/entities/appointment_entity.dart';
import 'package:appoinment_app/features/appointments/domain/repositories/appointment_repository.dart';

class BookAppointmentUseCase implements UseCase<void, AppointmentEntity> {
  final AppointmentRepository repository;
  BookAppointmentUseCase(this.repository);

  @override
  Future<void> call(AppointmentEntity appointment) {
    return repository.bookAppointment(appointment);
  }
}
