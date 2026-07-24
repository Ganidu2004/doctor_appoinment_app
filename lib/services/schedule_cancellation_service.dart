// lib/services/schedule_cancellation_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:appoinment_app/screens/dashboard/appoiment/modles/cancellation_invoice.dart';
import 'package:appoinment_app/services/notification_services.dart';

class ScheduleCancellationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches active patient appointments matching doctorId and schedule day/time
  Future<List<Map<String, dynamic>>> getAffectedAppointments({
    required String doctorId,
    required String day,
    String? startTime,
    String? endTime,
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

        if (startTime != null && endTime != null && apptTime.isNotEmpty) {
          if (apptTime == startTime || apptTime == "$startTime - $endTime" || apptTime.contains(startTime)) {
            affected.add(data);
          } else {
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

  /// Processes schedule cancellation: Creates a single cancellation invoice per booking (Pending Patient Choice)
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
          issuedAt: Timestamp.now(),
        );

        // 1. Save single cancellation invoice
        await invRef.set(invoice.toMap());

        // 2. Update payment status to Cancellation Pending
        if (paymentId.isNotEmpty) {
          await _firestore.collection('payments').doc(paymentId).update({
            'paymentStatus': 'Cancellation Pending',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // 3. Update appointment status to Cancelled (Pending Resolution)
        await _firestore.collection('appointments').doc(apptId).update({
          'status': 'Cancelled (Pending Resolution)',
          'cancellationInvoiceId': invRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 4. Send notification to patient
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

  /// Patient Option A: Claim Full Refund
  Future<bool> resolveInvoiceByRefund({
    required String invoiceId,
    required String appointmentId,
    String? paymentId,
  }) async {
    try {
      // 1. Update Invoice
      await _firestore.collection('invoices').doc(invoiceId).update({
        'actionType': 'Refund',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update Appointment Status
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'Cancelled (Refunded)',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update Payment Status
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

  /// Patient Option B: Reschedule to Another Date/Time Slot
  Future<bool> resolveInvoiceByReschedule({
    required String invoiceId,
    required String appointmentId,
    required String newDate,
    required String newTime,
    String? paymentId,
  }) async {
    try {
      // 1. Update Invoice
      await _firestore.collection('invoices').doc(invoiceId).update({
        'actionType': 'Rescheduled',
        'resolvedAt': FieldValue.serverTimestamp(),
        'rescheduledToDate': newDate,
        'rescheduledToTime': newTime,
      });

      // 2. Update Appointment to new Date & Time, active status
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'Booked',
        'date': newDate,
        'time': newTime,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update Payment Status to Rescheduled Credit
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
