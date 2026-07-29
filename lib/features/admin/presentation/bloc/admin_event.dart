import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class FetchAllPaymentsEvent extends AdminEvent {}

class UpdatePaymentStatusEvent extends AdminEvent {
  final String paymentId;
  final String status;

  const UpdatePaymentStatusEvent({
    required this.paymentId,
    required this.status,
  });

  @override
  List<Object?> get props => [paymentId, status];
}

class DeletePaymentEvent extends AdminEvent {
  final String paymentId;

  const DeletePaymentEvent({required this.paymentId});

  @override
  List<Object?> get props => [paymentId];
}
