class AppointmentEntity {
  final String id;
  final String doctorId;
  final String patientUid;
  final String date;
  final String time;
  final String status;
  final double consultationFee;
  final double hospitalCharges;
  final String paymentId;
  final String paymentMethod;
  final DateTime createdAt;

  const AppointmentEntity({
    required this.id,
    required this.doctorId,
    required this.patientUid,
    required this.date,
    required this.time,
    required this.status,
    required this.consultationFee,
    required this.hospitalCharges,
    required this.paymentId,
    required this.paymentMethod,
    required this.createdAt,
  });
}
