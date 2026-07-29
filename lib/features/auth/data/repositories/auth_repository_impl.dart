import 'package:appoinment_app/features/auth/domain/entities/auth_user_entity.dart';
import 'package:appoinment_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:appoinment_app/features/auth/data/datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AuthUserEntity?> getCurrentUser() {
    return remoteDataSource.getCurrentUser();
  }

  @override
  Future<AuthUserEntity> signInWithEmailAndPassword(String email, String password) {
    return remoteDataSource.signIn(email, password);
  }

  @override
  Future<AuthUserEntity> signUpWithEmailAndPassword(String email, String password) {
    return remoteDataSource.signUp(email, password);
  }

  @override
  Future<void> signOut() {
    return remoteDataSource.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return remoteDataSource.sendPasswordResetEmail(email);
  }
}
