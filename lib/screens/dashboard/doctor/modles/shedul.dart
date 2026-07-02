// lib/models/schedule_model.dart

class ScheduleModel {
  final String id;            
  final String day;          
  final String startTime;
  final String endTime;
  final int maxPatients;
  final double? consultationFee;
  final String hospitalName;
  final String hospitalPhone; 
  final bool isActive;       

  ScheduleModel({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.maxPatients,
    required this.consultationFee,
    required this.hospitalName,
    required this.hospitalPhone, 
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'maxPatients': maxPatients,
      'consultationFee': consultationFee ?? 0.0,
      'hospitalName': hospitalName,
      'hospitalPhone': hospitalPhone, 
      'isActive': isActive,
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'] ?? '',
      day: map['day'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      maxPatients: map['maxPatients'] is num
          ? (map['maxPatients'] as num).toInt()
          : int.tryParse(map['maxPatients']?.toString() ?? '') ?? 0,
      consultationFee: _parseFee(map['consultationFee']),
      hospitalName: map['hospitalName'] ?? '',
      hospitalPhone: map['hospitalPhone'] ?? '', 
      isActive: map['isActive'] ?? true,
    );
  }

  static double _parseFee(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}