import 'package:equatable/equatable.dart';
import 'package:appoinment_app/features/appointments/domain/entities/appointment_entity.dart';

abstract class AppointmentEvent extends Equatable {
  const AppointmentEvent();

  @override
  List<Object?> get props => [];
}

class BookAppointmentEvent extends AppointmentEvent {
  final AppointmentEntity appointment;

  const BookAppointmentEvent({required this.appointment});

  @override
  List<Object?> get props => [appointment];
}

class UpdateAppointmentStatusEvent extends AppointmentEvent {
  final String appointmentId;
  final String status;

  const UpdateAppointmentStatusEvent({
    required this.appointmentId,
    required this.status,
  });

  @override
  List<Object?> get props => [appointmentId, status];
}

class FetchPatientAppointmentsEvent extends AppointmentEvent {
  final String patientUid;

  const FetchPatientAppointmentsEvent({required this.patientUid});

  @override
  List<Object?> get props => [patientUid];
}

class FetchDoctorAppointmentsEvent extends AppointmentEvent {
  final String doctorUid;

  const FetchDoctorAppointmentsEvent({required this.doctorUid});

  @override
  List<Object?> get props => [doctorUid];
}
