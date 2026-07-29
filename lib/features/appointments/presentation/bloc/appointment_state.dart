import 'package:equatable/equatable.dart';
import 'package:appoinment_app/features/appointments/domain/entities/appointment_entity.dart';

abstract class AppointmentState extends Equatable {
  const AppointmentState();

  @override
  List<Object?> get props => [];
}

class AppointmentInitial extends AppointmentState {}

class AppointmentLoading extends AppointmentState {}

class AppointmentBookedSuccess extends AppointmentState {
  final String message;

  const AppointmentBookedSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class AppointmentsLoaded extends AppointmentState {
  final List<AppointmentEntity> appointments;

  const AppointmentsLoaded({required this.appointments});

  @override
  List<Object?> get props => [appointments];
}

class AppointmentOperationSuccess extends AppointmentState {
  final String message;

  const AppointmentOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class AppointmentError extends AppointmentState {
  final String message;

  const AppointmentError({required this.message});

  @override
  List<Object?> get props => [message];
}
