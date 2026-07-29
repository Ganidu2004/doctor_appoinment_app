import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:appoinment_app/core/config.dart';
import 'package:appoinment_app/core/theme.dart';
import 'package:appoinment_app/core/services/notification_services.dart';
import 'firebase_options.dart';

// Repositories & DataSources
import 'package:appoinment_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:appoinment_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:appoinment_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:appoinment_app/features/auth/presentation/bloc/auth_event.dart';

import 'package:appoinment_app/features/patient/data/datasources/patient_remote_datasource.dart';
import 'package:appoinment_app/features/patient/data/repositories/patient_repository_impl.dart';
import 'package:appoinment_app/features/patient/presentation/bloc/patient_bloc.dart';

import 'package:appoinment_app/features/doctor/data/datasources/doctor_remote_datasource.dart';
import 'package:appoinment_app/features/doctor/data/repositories/doctor_repository_impl.dart';
import 'package:appoinment_app/features/doctor/presentation/bloc/doctor_bloc.dart';

import 'package:appoinment_app/features/appointments/data/datasources/appointment_remote_datasource.dart';
import 'package:appoinment_app/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:appoinment_app/features/appointments/presentation/bloc/appointment_bloc.dart';

import 'package:appoinment_app/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:appoinment_app/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:appoinment_app/features/admin/presentation/bloc/admin_bloc.dart';

import 'package:appoinment_app/features/auth/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  NotificationService().initNotifications().catchError((e) {
    debugPrint("Notification init error: $e");
  });

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseKey,
    );
  } catch (e) {
    debugPrint("Supabase init error: $e");
  }

  // Dependencies initialization
  final firebaseAuth = FirebaseAuth.instance;
  final firebaseFirestore = FirebaseFirestore.instance;

  final authRepository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(firebaseAuth: firebaseAuth),
  );
  final patientRepository = PatientRepositoryImpl(
    remoteDataSource: PatientRemoteDataSourceImpl(firestore: firebaseFirestore),
  );
  final doctorRepository = DoctorRepositoryImpl(
    remoteDataSource: DoctorRemoteDataSourceImpl(firestore: firebaseFirestore),
  );
  final appointmentRepository = AppointmentRepositoryImpl(
    remoteDataSource: AppointmentRemoteDataSourceImpl(firestore: firebaseFirestore),
  );
  final adminRepository = AdminRepositoryImpl(
    remoteDataSource: AdminRemoteDataSourceImpl(firestore: firebaseFirestore),
  );

  runApp(MyApp(
    authRepository: authRepository,
    patientRepository: patientRepository,
    doctorRepository: doctorRepository,
    appointmentRepository: appointmentRepository,
    adminRepository: adminRepository,
  ));
}

class MyApp extends StatelessWidget {
  final AuthRepositoryImpl authRepository;
  final PatientRepositoryImpl patientRepository;
  final DoctorRepositoryImpl doctorRepository;
  final AppointmentRepositoryImpl appointmentRepository;
  final AdminRepositoryImpl adminRepository;

  const MyApp({
    super.key,
    required this.authRepository,
    required this.patientRepository,
    required this.doctorRepository,
    required this.appointmentRepository,
    required this.adminRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository: authRepository)..add(AuthCheckRequested()),
        ),
        BlocProvider<PatientBloc>(
          create: (_) => PatientBloc(patientRepository: patientRepository),
        ),
        BlocProvider<DoctorBloc>(
          create: (_) => DoctorBloc(doctorRepository: doctorRepository),
        ),
        BlocProvider<AppointmentBloc>(
          create: (_) => AppointmentBloc(appointmentRepository: appointmentRepository),
        ),
        BlocProvider<AdminBloc>(
          create: (_) => AdminBloc(adminRepository: adminRepository),
        ),
      ],
      child: MaterialApp(
        title: 'DOC Time',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
