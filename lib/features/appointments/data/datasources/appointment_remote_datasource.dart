import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appoinment_app/features/appointments/data/models/appointment_model.dart';
import 'package:appoinment_app/features/appointments/data/models/cancellation_invoice_model.dart';
import 'package:appoinment_app/core/error/exceptions.dart';

abstract class AppointmentRemoteDataSource {
  Future<void> bookAppointment(AppointmentModel appointment);
  Future<void> updateAppointmentStatus(String appointmentId, String status);
  Stream<List<AppointmentModel>> getPatientAppointments(String patientUid);
  Stream<List<AppointmentModel>> getDoctorAppointments(String doctorUid);
  Future<CancellationInvoiceModel?> getCancellationInvoice(String invoiceId);
}

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  final FirebaseFirestore firestore;

  AppointmentRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> bookAppointment(AppointmentModel appointment) async {
    try {
      await firestore.collection('appointments').add(appointment.toMap());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await firestore.collection('appointments').doc(appointmentId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<List<AppointmentModel>> getPatientAppointments(String patientUid) {
    return firestore
        .collection('appointments')
        .where('patientUid', isEqualTo: patientUid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppointmentModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  @override
  Stream<List<AppointmentModel>> getDoctorAppointments(String doctorUid) {
    return firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorUid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppointmentModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  @override
  Future<CancellationInvoiceModel?> getCancellationInvoice(String invoiceId) async {
    try {
      final doc = await firestore.collection('invoices').doc(invoiceId).get();
      if (!doc.exists || doc.data() == null) return null;
      return CancellationInvoiceModel.fromMap(doc.data()!, id: doc.id);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
