import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appoinment_app/features/patient/domain/repositories/patient_repository.dart';
import 'patient_event.dart';
import 'patient_state.dart';

class PatientBloc extends Bloc<PatientEvent, PatientState> {
  final PatientRepository patientRepository;

  PatientBloc({required this.patientRepository}) : super(PatientInitial()) {
    on<FetchPatientProfileEvent>(_onFetchPatientProfile);
    on<CreatePatientProfileEvent>(_onCreatePatientProfile);
    on<UpdatePatientProfileEvent>(_onUpdatePatientProfile);
    on<FetchAllPatientsEvent>(_onFetchAllPatients);
  }

  Future<void> _onFetchPatientProfile(
    FetchPatientProfileEvent event,
    Emitter<PatientState> emit,
  ) async {
    emit(PatientLoading());
    try {
      final patient = await patientRepository.getPatientProfile(event.uid);
      emit(PatientProfileLoaded(patient: patient));
    } catch (e) {
      emit(PatientError(message: e.toString()));
    }
  }

  Future<void> _onCreatePatientProfile(
    CreatePatientProfileEvent event,
    Emitter<PatientState> emit,
  ) async {
    emit(PatientLoading());
    try {
      await patientRepository.createPatientProfile(event.patient);
      emit(const PatientOperationSuccess(message: 'Patient profile created successfully'));
    } catch (e) {
      emit(PatientError(message: e.toString()));
    }
  }

  Future<void> _onUpdatePatientProfile(
    UpdatePatientProfileEvent event,
    Emitter<PatientState> emit,
  ) async {
    emit(PatientLoading());
    try {
      await patientRepository.updatePatientProfile(event.patient);
      emit(const PatientOperationSuccess(message: 'Patient profile updated successfully'));
    } catch (e) {
      emit(PatientError(message: e.toString()));
    }
  }

  Future<void> _onFetchAllPatients(
    FetchAllPatientsEvent event,
    Emitter<PatientState> emit,
  ) async {
    emit(PatientLoading());
    try {
      await emit.forEach(
        patientRepository.getAllPatients(),
        onData: (patients) => AllPatientsLoaded(patients: patients),
        onError: (e, _) => PatientError(message: e.toString()),
      );
    } catch (e) {
      emit(PatientError(message: e.toString()));
    }
  }
}
