import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appoinment_app/features/doctor/domain/repositories/doctor_repository.dart';
import 'doctor_event.dart';
import 'doctor_state.dart';

class DoctorBloc extends Bloc<DoctorEvent, DoctorState> {
  final DoctorRepository doctorRepository;

  DoctorBloc({required this.doctorRepository}) : super(DoctorInitial()) {
    on<FetchDoctorProfileEvent>(_onFetchDoctorProfile);
    on<CreateDoctorProfileEvent>(_onCreateDoctorProfile);
    on<UpdateDoctorProfileEvent>(_onUpdateDoctorProfile);
    on<FetchAllDoctorsEvent>(_onFetchAllDoctors);
    on<UpdateDoctorSchedulesEvent>(_onUpdateDoctorSchedules);
  }

  Future<void> _onFetchDoctorProfile(
    FetchDoctorProfileEvent event,
    Emitter<DoctorState> emit,
  ) async {
    emit(DoctorLoading());
    try {
      final doctor = await doctorRepository.getDoctorProfile(event.uid);
      emit(DoctorProfileLoaded(doctor: doctor));
    } catch (e) {
      emit(DoctorError(message: e.toString()));
    }
  }

  Future<void> _onCreateDoctorProfile(
    CreateDoctorProfileEvent event,
    Emitter<DoctorState> emit,
  ) async {
    emit(DoctorLoading());
    try {
      await doctorRepository.createDoctorProfile(event.doctor);
      emit(const DoctorOperationSuccess(message: 'Doctor profile created successfully'));
    } catch (e) {
      emit(DoctorError(message: e.toString()));
    }
  }

  Future<void> _onUpdateDoctorProfile(
    UpdateDoctorProfileEvent event,
    Emitter<DoctorState> emit,
  ) async {
    emit(DoctorLoading());
    try {
      await doctorRepository.updateDoctorProfile(event.doctor);
      emit(const DoctorOperationSuccess(message: 'Doctor profile updated successfully'));
    } catch (e) {
      emit(DoctorError(message: e.toString()));
    }
  }

  Future<void> _onFetchAllDoctors(
    FetchAllDoctorsEvent event,
    Emitter<DoctorState> emit,
  ) async {
    emit(DoctorLoading());
    try {
      await emit.forEach(
        doctorRepository.getAllDoctors(),
        onData: (doctors) => AllDoctorsLoaded(doctors: doctors),
        onError: (e, _) => DoctorError(message: e.toString()),
      );
    } catch (e) {
      emit(DoctorError(message: e.toString()));
    }
  }

  Future<void> _onUpdateDoctorSchedules(
    UpdateDoctorSchedulesEvent event,
    Emitter<DoctorState> emit,
  ) async {
    emit(DoctorLoading());
    try {
      await doctorRepository.updateDoctorSchedules(
        event.doctorUid,
        event.schedules,
      );
      emit(const DoctorOperationSuccess(message: 'Schedules updated successfully'));
    } catch (e) {
      emit(DoctorError(message: e.toString()));
    }
  }
}
