import 'package:equatable/equatable.dart';
import 'package:appoinment_app/features/patient/domain/entities/patient_entity.dart';

abstract class PatientState extends Equatable {
  const PatientState();

  @override
  List<Object?> get props => [];
}

class PatientInitial extends PatientState {}

class PatientLoading extends PatientState {}

class PatientProfileLoaded extends PatientState {
  final PatientEntity? patient;

  const PatientProfileLoaded({required this.patient});

  @override
  List<Object?> get props => [patient];
}

class AllPatientsLoaded extends PatientState {
  final List<PatientEntity> patients;

  const AllPatientsLoaded({required this.patients});

  @override
  List<Object?> get props => [patients];
}

class PatientOperationSuccess extends PatientState {
  final String message;

  const PatientOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class PatientError extends PatientState {
  final String message;

  const PatientError({required this.message});

  @override
  List<Object?> get props => [message];
}
