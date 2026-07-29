import 'package:appoinment_app/core/usecase/usecase.dart';
import 'package:appoinment_app/features/appointments/domain/repositories/appointment_repository.dart';

class CancelAppointmentParams {
  final String appointmentId;
  final String status;
  const CancelAppointmentParams({required this.appointmentId, required this.status});
}

class CancelAppointmentUseCase implements UseCase<void, CancelAppointmentParams> {
  final AppointmentRepository repository;
  CancelAppointmentUseCase(this.repository);

  @override
  Future<void> call(CancelAppointmentParams params) {
    return repository.updateAppointmentStatus(params.appointmentId, params.status);
  }
}
