import 'package:appoinment_app/features/appointments/domain/entities/appointment_entity.dart';
import 'package:appoinment_app/features/appointments/domain/entities/cancellation_invoice_entity.dart';

abstract class AppointmentRepository {
  Future<void> bookAppointment(AppointmentEntity appointment);
  Future<void> updateAppointmentStatus(String appointmentId, String status);
  Stream<List<AppointmentEntity>> getPatientAppointments(String patientUid);
  Stream<List<AppointmentEntity>> getDoctorAppointments(String doctorUid);
  Future<CancellationInvoiceEntity?> getCancellationInvoice(String invoiceId);
}
