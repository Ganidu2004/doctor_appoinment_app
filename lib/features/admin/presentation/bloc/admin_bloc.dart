import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appoinment_app/features/admin/domain/repositories/admin_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository adminRepository;

  AdminBloc({required this.adminRepository}) : super(AdminInitial()) {
    on<FetchAllPaymentsEvent>(_onFetchAllPayments);
    on<UpdatePaymentStatusEvent>(_onUpdatePaymentStatus);
    on<DeletePaymentEvent>(_onDeletePayment);
  }

  Future<void> _onFetchAllPayments(
    FetchAllPaymentsEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await emit.forEach(
        adminRepository.getAllPayments(),
        onData: (payments) => PaymentsLoaded(payments: payments),
        onError: (e, _) => AdminError(message: e.toString()),
      );
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onUpdatePaymentStatus(
    UpdatePaymentStatusEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await adminRepository.updatePaymentStatus(event.paymentId, event.status);
      emit(const AdminOperationSuccess(message: 'Payment status updated successfully'));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }

  Future<void> _onDeletePayment(
    DeletePaymentEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await adminRepository.deletePayment(event.paymentId);
      emit(const AdminOperationSuccess(message: 'Payment deleted successfully'));
    } catch (e) {
      emit(AdminError(message: e.toString()));
    }
  }
}
