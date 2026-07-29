import 'package:equatable/equatable.dart';
import 'package:appoinment_app/features/patient/domain/entities/patient_entity.dart';

abstract class PatientEvent extends Equatable {
  const PatientEvent();

  @override
  List<Object?> get props => [];
}

class FetchPatientProfileEvent extends PatientEvent {
  final String uid;

  const FetchPatientProfileEvent({required this.uid});

  @override
  List<Object?> get props => [uid];
}

class CreatePatientProfileEvent extends PatientEvent {
  final PatientEntity patient;

  const CreatePatientProfileEvent({required this.patient});

  @override
  List<Object?> get props => [patient];
}

class UpdatePatientProfileEvent extends PatientEvent {
  final PatientEntity patient;

  const UpdatePatientProfileEvent({required this.patient});

  @override
  List<Object?> get props => [patient];
}

class FetchAllPatientsEvent extends PatientEvent {}
