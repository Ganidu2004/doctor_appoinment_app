import 'package:equatable/equatable.dart';
import 'package:appoinment_app/features/doctor/domain/entities/doctor_entity.dart';

abstract class DoctorState extends Equatable {
  const DoctorState();

  @override
  List<Object?> get props => [];
}

class DoctorInitial extends DoctorState {}

class DoctorLoading extends DoctorState {}

class DoctorProfileLoaded extends DoctorState {
  final DoctorEntity? doctor;

  const DoctorProfileLoaded({required this.doctor});

  @override
  List<Object?> get props => [doctor];
}

class AllDoctorsLoaded extends DoctorState {
  final List<DoctorEntity> doctors;

  const AllDoctorsLoaded({required this.doctors});

  @override
  List<Object?> get props => [doctors];
}

class DoctorOperationSuccess extends DoctorState {
  final String message;

  const DoctorOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class DoctorError extends DoctorState {
  final String message;

  const DoctorError({required this.message});

  @override
  List<Object?> get props => [message];
}
