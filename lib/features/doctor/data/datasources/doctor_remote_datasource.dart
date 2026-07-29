import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appoinment_app/features/doctor/data/models/doctor_model.dart';
import 'package:appoinment_app/features/doctor/data/models/schedule_model.dart';
import 'package:appoinment_app/core/error/exceptions.dart';

abstract class DoctorRemoteDataSource {
  Future<DoctorModel?> getDoctorProfile(String uid);
  Future<void> createDoctorProfile(DoctorModel doctor);
  Future<void> updateDoctorProfile(DoctorModel doctor);
  Stream<List<DoctorModel>> getAllDoctors();
  Future<void> updateDoctorSchedules(String doctorUid, List<ScheduleModel> schedules);
}

class DoctorRemoteDataSourceImpl implements DoctorRemoteDataSource {
  final FirebaseFirestore firestore;

  DoctorRemoteDataSourceImpl({required this.firestore});

  @override
  Future<DoctorModel?> getDoctorProfile(String uid) async {
    try {
      final doc = await firestore.collection('doctors').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return DoctorModel.fromMap(doc.data()!);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> createDoctorProfile(DoctorModel doctor) async {
    try {
      await firestore.collection('doctors').doc(doctor.uid).set(doctor.toMap());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateDoctorProfile(DoctorModel doctor) async {
    try {
      await firestore.collection('doctors').doc(doctor.uid).update(doctor.toMap());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<List<DoctorModel>> getAllDoctors() {
    return firestore.collection('doctors').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => DoctorModel.fromMap(doc.data())).toList();
    });
  }

  @override
  Future<void> updateDoctorSchedules(String doctorUid, List<ScheduleModel> schedules) async {
    try {
      await firestore.collection('doctors').doc(doctorUid).update({
        'schedules': schedules.map((s) => s.toMap()).toList(),
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
