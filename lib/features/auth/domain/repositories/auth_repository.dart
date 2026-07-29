import 'package:appoinment_app/features/auth/domain/entities/auth_user_entity.dart';

abstract class AuthRepository {
  Future<AuthUserEntity?> getCurrentUser();
  Future<AuthUserEntity> signInWithEmailAndPassword(String email, String password);
  Future<AuthUserEntity> signUpWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
}
