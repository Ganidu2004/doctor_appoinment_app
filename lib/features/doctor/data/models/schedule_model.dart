import 'package:appoinment_app/features/doctor/domain/entities/schedule_entity.dart';

class ScheduleModel extends ScheduleEntity {
  const ScheduleModel({
    required super.id,
    required super.day,
    required super.startTime,
    required super.endTime,
    required super.maxPatients,
    required super.consultationFee,
    required super.hospitalId,
    required super.hospitalName,
    required super.hospitalPhone,
    required super.isActive,
    super.disabledDates = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'maxPatients': maxPatients,
      'consultationFee': consultationFee ?? 0.0,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'hospitalPhone': hospitalPhone,
      'isActive': isActive,
      'disabledDates': disabledDates,
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedDisabledDates = [];
    if (map['disabledDates'] != null && map['disabledDates'] is List) {
      parsedDisabledDates = List<String>.from(map['disabledDates'].map((e) => e.toString()));
    }

    return ScheduleModel(
      id: map['id'] ?? '',
      day: map['day'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      maxPatients: map['maxPatients'] is num
          ? (map['maxPatients'] as num).toInt()
          : int.tryParse(map['maxPatients']?.toString() ?? '') ?? 0,
      consultationFee: _parseFee(map['consultationFee']),
      hospitalId: map['hospitalId'] ?? '',
      hospitalName: map['hospitalName'] ?? '',
      hospitalPhone: map['hospitalPhone'] ?? '',
      isActive: map['isActive'] ?? true,
      disabledDates: parsedDisabledDates,
    );
  }

  factory ScheduleModel.fromEntity(ScheduleEntity entity) {
    return ScheduleModel(
      id: entity.id,
      day: entity.day,
      startTime: entity.startTime,
      endTime: entity.endTime,
      maxPatients: entity.maxPatients,
      consultationFee: entity.consultationFee,
      hospitalId: entity.hospitalId,
      hospitalName: entity.hospitalName,
      hospitalPhone: entity.hospitalPhone,
      isActive: entity.isActive,
      disabledDates: entity.disabledDates,
    );
  }

  static double _parseFee(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
