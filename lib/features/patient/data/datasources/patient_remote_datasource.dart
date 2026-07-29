import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appoinment_app/features/patient/data/models/patient_model.dart';
import 'package:appoinment_app/core/error/exceptions.dart';

abstract class PatientRemoteDataSource {
  Future<PatientModel?> getPatientProfile(String uid);
  Future<void> createPatientProfile(PatientModel patient);
  Future<void> updatePatientProfile(PatientModel patient);
  Stream<List<PatientModel>> getAllPatients();
}

class PatientRemoteDataSourceImpl implements PatientRemoteDataSource {
  final FirebaseFirestore firestore;

  PatientRemoteDataSourceImpl({required this.firestore});

  @override
  Future<PatientModel?> getPatientProfile(String uid) async {
    try {
      final doc = await firestore.collection('patients').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return PatientModel.fromMap(doc.data()!);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> createPatientProfile(PatientModel patient) async {
    try {
      await firestore.collection('patients').doc(patient.uid).set(patient.toMap());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updatePatientProfile(PatientModel patient) async {
    try {
      await firestore.collection('patients').doc(patient.uid).update(patient.toMap());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<List<PatientModel>> getAllPatients() {
    return firestore.collection('patients').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PatientModel.fromMap(doc.data())).toList();
    });
  }
}
