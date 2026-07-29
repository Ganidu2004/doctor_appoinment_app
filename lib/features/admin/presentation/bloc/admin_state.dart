import 'package:equatable/equatable.dart';
import 'package:appoinment_app/features/admin/domain/entities/payment_entity.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class PaymentsLoaded extends AdminState {
  final List<PaymentEntity> payments;

  const PaymentsLoaded({required this.payments});

  @override
  List<Object?> get props => [payments];
}

class AdminOperationSuccess extends AdminState {
  final String message;

  const AdminOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class AdminError extends AdminState {
  final String message;

  const AdminError({required this.message});

  @override
  List<Object?> get props => [message];
}
