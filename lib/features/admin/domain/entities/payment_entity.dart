class PaymentEntity {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final double amount;
  final double hospitalCharges;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime paymentDate;

  const PaymentEntity({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.amount,
    required this.hospitalCharges,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentDate,
  });
}
