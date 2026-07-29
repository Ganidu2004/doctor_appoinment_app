import 'package:appoinment_app/features/admin/domain/entities/payment_entity.dart';

abstract class AdminRepository {
  Stream<List<PaymentEntity>> getAllPayments();
  Future<void> updatePaymentStatus(String paymentId, String status);
  Future<void> deletePayment(String paymentId);
}
