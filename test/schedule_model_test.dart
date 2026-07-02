import 'package:appoinment_app/screens/dashboard/doctor/modles/shedul.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScheduleModel', () {
    test('serializes consultation fee with schedule data', () {
      final model = ScheduleModel(
        id: 'slot-1',
        day: 'Monday',
        startTime: '09:00 AM',
        endTime: '10:00 AM',
        maxPatients: 10,
        consultationFee: 75.5,
        hospitalName: 'City Clinic',
        hospitalPhone: '123456',
        isActive: true,
      );

      final map = model.toMap();

      expect(map['consultationFee'], 75.5);

      final decoded = ScheduleModel.fromMap(map);
      expect(decoded.consultationFee, 75.5);
    });
  });
}
