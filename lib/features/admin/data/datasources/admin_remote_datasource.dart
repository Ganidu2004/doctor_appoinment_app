import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appoinment_app/features/admin/data/models/payment_model.dart';
import 'package:appoinment_app/core/error/exceptions.dart';

abstract class AdminRemoteDataSource {
  Stream<List<PaymentModel>> getAllPayments();
  Future<void> updatePaymentStatus(String paymentId, String status);
  Future<void> deletePayment(String paymentId);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final FirebaseFirestore firestore;

  AdminRemoteDataSourceImpl({required this.firestore});

  @override
  Stream<List<PaymentModel>> getAllPayments() {
    return firestore.collection('payments').snapshots().map((snap) =>
        snap.docs.map((doc) => PaymentModel.fromMap(doc.data(), id: doc.id)).toList());
  }

  @override
  Future<void> updatePaymentStatus(String paymentId, String status) async {
    try {
      await firestore.collection('payments').doc(paymentId).update({
        'paymentStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deletePayment(String paymentId) async {
    try {
      await firestore.collection('payments').doc(paymentId).delete();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
