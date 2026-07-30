import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:appoinment_app/features/appointments/data/models/cancellation_invoice_model.dart';
import 'package:appoinment_app/core/services/notification_services.dart';

class ScheduleCancellationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getAffectedAppointments({
    required String doctorId,
    required String day,
    String? startTime,
    String? endTime,
    String? targetDate,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', whereIn: ['Booked', 'Pending'])
          .get();

      List<Map<String, dynamic>> affected = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final apptTime = (data['time'] ?? '').toString();
        final apptDate = (data['date'] ?? '').toString();

        if (targetDate != null && targetDate.isNotEmpty) {
          if (apptDate != targetDate) {
            continue;
          }
        }

        if (startTime != null && endTime != null && apptTime.isNotEmpty) {
          if (apptTime == startTime || apptTime == "$startTime - $endTime" || apptTime.contains(startTime)) {
            affected.add(data);
          }
        } else {
          affected.add(data);
        }
      }

      return affected;
    } catch (e) {
      debugPrint("Error fetching affected appointments: $e");
      return [];
    }
  }

  Future<int> processScheduleCancellation({
    required String doctorId,
    required String day,
    String actionType = 'Pending Patient Choice',
    required List<Map<String, dynamic>> affectedAppointments,
    String reason = 'Doctor schedule set to Off or cancelled.',
  }) async {
    if (affectedAppointments.isEmpty) return 0;

    int successCount = 0;
    final random = Random();

    for (var appt in affectedAppointments) {
      try {
        final apptId = appt['id'] ?? '';
        final patientUid = appt['patientUid'] ?? '';
        final apptDate = appt['date'] ?? day;
        final apptTime = appt['time'] ?? '';
        final fee = (appt['consultationFee'] is num ? (appt['consultationFee'] as num).toDouble() : 0.0);
        final hospitalCharges = (appt['hospitalCharges'] is num ? (appt['hospitalCharges'] as num).toDouble() : 0.0);
        final total = fee + hospitalCharges;
        final paymentId = appt['paymentId'] ?? '';
        final paymentMethod = appt['paymentMethod'] ?? 'Online';

        final String invNum = "INV-${DateTime.now().year}-${(100000 + random.nextInt(900000))}";
        final invRef = _firestore.collection('invoices').doc();

        final invoice = CancellationInvoiceModel(
          id: invRef.id,
          invoiceNumber: invNum,
          appointmentId: apptId,
          patientId: patientUid,
          doctorId: doctorId,
          originalDate: apptDate,
          time: apptTime,
          totalAmount: total,
          consultationFee: fee,
          hospitalCharges: hospitalCharges,
          actionType: actionType,
          paymentMethod: paymentMethod,
          remarks: reason,
          issuedAt: DateTime.now(),
        );

        await invRef.set(invoice.toMap());

        if (paymentId.isNotEmpty) {
          await _firestore.collection('payments').doc(paymentId).update({
            'paymentStatus': 'Cancellation Pending',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        await _firestore.collection('appointments').doc(apptId).update({
          'status': 'Cancelled (Pending Resolution)',
          'cancellationInvoiceId': invRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (patientUid.isNotEmpty) {
          await _firestore.collection('notifications').add({
            'userId': patientUid,
            'title': 'Schedule Set to Off - Invoice Issued',
            'body': 'Your appointment on $apptDate at $apptTime was cancelled. Invoice $invNum has been generated. Please select Refund or Reschedule.',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'invoiceId': invRef.id,
          });
        }

        successCount++;
      } catch (e) {
        debugPrint("Error processing cancellation for appointment ${appt['id']}: $e");
      }
    }

    try {
      await NotificationService().showNotification(
        id: 301,
        title: 'Schedule Cancellation Invoices Issued',
        body: '$successCount cancellation invoice(s) generated for affected patients.',
      );
    } catch (err) {
      debugPrint('Notification error: $err');
    }

    return successCount;
  }

  Future<bool> resolveInvoiceByRefund({
    required String invoiceId,
    required String appointmentId,
    String? paymentId,
  }) async {
    try {
      await _firestore.collection('invoices').doc(invoiceId).update({
        'actionType': 'Refund',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'Cancelled (Refunded)',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (paymentId != null && paymentId.isNotEmpty) {
        await _firestore.collection('payments').doc(paymentId).update({
          'paymentStatus': 'Refunded',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      debugPrint("Error resolving refund: $e");
      return false;
    }
  }

  Future<bool> resolveInvoiceByReschedule({
    required String invoiceId,
    required String appointmentId,
    required String newDate,
    required String newTime,
    String? paymentId,
  }) async {
    try {
      await _firestore.collection('invoices').doc(invoiceId).update({
        'actionType': 'Rescheduled',
        'resolvedAt': FieldValue.serverTimestamp(),
        'rescheduledToDate': newDate,
        'rescheduledToTime': newTime,
      });

      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'Booked',
        'date': newDate,
        'time': newTime,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (paymentId != null && paymentId.isNotEmpty) {
        await _firestore.collection('payments').doc(paymentId).update({
          'paymentStatus': 'Rescheduled Credit',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      debugPrint("Error resolving reschedule: $e");
      return false;
    }
  }
}
