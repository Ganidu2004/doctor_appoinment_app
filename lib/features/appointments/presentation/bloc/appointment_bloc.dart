import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appoinment_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'appointment_event.dart';
import 'appointment_state.dart';

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final AppointmentRepository appointmentRepository;

  AppointmentBloc({required this.appointmentRepository}) : super(AppointmentInitial()) {
    on<BookAppointmentEvent>(_onBookAppointment);
    on<UpdateAppointmentStatusEvent>(_onUpdateAppointmentStatus);
    on<FetchPatientAppointmentsEvent>(_onFetchPatientAppointments);
    on<FetchDoctorAppointmentsEvent>(_onFetchDoctorAppointments);
  }

  Future<void> _onBookAppointment(
    BookAppointmentEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    try {
      await appointmentRepository.bookAppointment(event.appointment);
      emit(const AppointmentBookedSuccess(message: 'Appointment booked successfully'));
    } catch (e) {
      emit(AppointmentError(message: e.toString()));
    }
  }

  Future<void> _onUpdateAppointmentStatus(
    UpdateAppointmentStatusEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    try {
      await appointmentRepository.updateAppointmentStatus(
        event.appointmentId,
        event.status,
      );
      emit(const AppointmentOperationSuccess(message: 'Appointment status updated'));
    } catch (e) {
      emit(AppointmentError(message: e.toString()));
    }
  }

  Future<void> _onFetchPatientAppointments(
    FetchPatientAppointmentsEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    try {
      await emit.forEach(
        appointmentRepository.getPatientAppointments(event.patientUid),
        onData: (appointments) => AppointmentsLoaded(appointments: appointments),
        onError: (e, _) => AppointmentError(message: e.toString()),
      );
    } catch (e) {
      emit(AppointmentError(message: e.toString()));
    }
  }

  Future<void> _onFetchDoctorAppointments(
    FetchDoctorAppointmentsEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    try {
      await emit.forEach(
        appointmentRepository.getDoctorAppointments(event.doctorUid),
        onData: (appointments) => AppointmentsLoaded(appointments: appointments),
        onError: (e, _) => AppointmentError(message: e.toString()),
      );
    } catch (e) {
      emit(AppointmentError(message: e.toString()));
    }
  }
}
