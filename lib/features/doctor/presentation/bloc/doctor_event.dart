import 'package:equatable/equatable.dart';
import 'package:appoinment_app/features/doctor/domain/entities/doctor_entity.dart';
import 'package:appoinment_app/features/doctor/domain/entities/schedule_entity.dart';

abstract class DoctorEvent extends Equatable {
  const DoctorEvent();

  @override
  List<Object?> get props => [];
}

class FetchDoctorProfileEvent extends DoctorEvent {
  final String uid;

  const FetchDoctorProfileEvent({required this.uid});

  @override
  List<Object?> get props => [uid];
}

class CreateDoctorProfileEvent extends DoctorEvent {
  final DoctorEntity doctor;

  const CreateDoctorProfileEvent({required this.doctor});

  @override
  List<Object?> get props => [doctor];
}

class UpdateDoctorProfileEvent extends DoctorEvent {
  final DoctorEntity doctor;

  const UpdateDoctorProfileEvent({required this.doctor});

  @override
  List<Object?> get props => [doctor];
}

class FetchAllDoctorsEvent extends DoctorEvent {}

class UpdateDoctorSchedulesEvent extends DoctorEvent {
  final String doctorUid;
  final List<ScheduleEntity> schedules;

  const UpdateDoctorSchedulesEvent({
    required this.doctorUid,
    required this.schedules,
  });

  @override
  List<Object?> get props => [doctorUid, schedules];
}
