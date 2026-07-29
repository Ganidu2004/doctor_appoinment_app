import 'package:appoinment_app/features/admin/domain/entities/payment_entity.dart';
import 'package:appoinment_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:appoinment_app/features/admin/data/datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<PaymentEntity>> getAllPayments() {
    return remoteDataSource.getAllPayments();
  }

  @override
  Future<void> updatePaymentStatus(String paymentId, String status) {
    return remoteDataSource.updatePaymentStatus(paymentId, status);
  }

  @override
  Future<void> deletePayment(String paymentId) {
    return remoteDataSource.deletePayment(paymentId);
  }
}
