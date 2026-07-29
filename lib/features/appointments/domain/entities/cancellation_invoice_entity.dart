class CancellationInvoiceEntity {
  final String id;
  final String invoiceNumber;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final String originalDate;
  final String time;
  final double totalAmount;
  final double consultationFee;
  final double hospitalCharges;
  final String actionType;
  final String paymentMethod;
  final String remarks;
  final DateTime issuedAt;

  const CancellationInvoiceEntity({
    required this.id,
    required this.invoiceNumber,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.originalDate,
    required this.time,
    required this.totalAmount,
    required this.consultationFee,
    required this.hospitalCharges,
    required this.actionType,
    required this.paymentMethod,
    required this.remarks,
    required this.issuedAt,
  });
}
