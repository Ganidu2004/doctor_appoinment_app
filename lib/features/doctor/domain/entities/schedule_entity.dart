class ScheduleEntity {
  final String id;
  final String day;
  final String startTime;
  final String endTime;
  final int maxPatients;
  final double? consultationFee;
  final String hospitalId;
  final String hospitalName;
  final String hospitalPhone;
  final bool isActive;

  const ScheduleEntity({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.maxPatients,
    required this.consultationFee,
    required this.hospitalId,
    required this.hospitalName,
    required this.hospitalPhone,
    required this.isActive,
  });
}
