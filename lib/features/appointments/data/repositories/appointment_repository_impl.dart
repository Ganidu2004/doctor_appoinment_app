import 'package:appoinment_app/features/appointments/domain/entities/appointment_entity.dart';
import 'package:appoinment_app/features/appointments/domain/entities/cancellation_invoice_entity.dart';
import 'package:appoinment_app/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:appoinment_app/features/appointments/data/datasources/appointment_remote_datasource.dart';
import 'package:appoinment_app/features/appointments/data/models/appointment_model.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource remoteDataSource;

  AppointmentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> bookAppointment(AppointmentEntity appointment) {
    return remoteDataSource.bookAppointment(AppointmentModel.fromEntity(appointment));
  }

  @override
  Future<void> updateAppointmentStatus(String appointmentId, String status) {
    return remoteDataSource.updateAppointmentStatus(appointmentId, status);
  }

  @override
  Stream<List<AppointmentEntity>> getPatientAppointments(String patientUid) {
    return remoteDataSource.getPatientAppointments(patientUid);
  }

  @override
  Stream<List<AppointmentEntity>> getDoctorAppointments(String doctorUid) {
    return remoteDataSource.getDoctorAppointments(doctorUid);
  }

  @override
  Future<CancellationInvoiceEntity?> getCancellationInvoice(String invoiceId) {
    return remoteDataSource.getCancellationInvoice(invoiceId);
  }
}
