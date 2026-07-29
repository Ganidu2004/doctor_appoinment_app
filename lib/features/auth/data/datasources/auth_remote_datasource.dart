import 'package:firebase_auth/firebase_auth.dart';
import 'package:appoinment_app/features/auth/domain/entities/auth_user_entity.dart';
import 'package:appoinment_app/core/error/exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<AuthUserEntity?> getCurrentUser();
  Future<AuthUserEntity> signIn(String email, String password);
  Future<AuthUserEntity> signUp(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;

  AuthRemoteDataSourceImpl({required this.firebaseAuth});

  @override
  Future<AuthUserEntity?> getCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;
    return AuthUserEntity(uid: user.uid, email: user.email ?? '');
  }

  @override
  Future<AuthUserEntity> signIn(String email, String password) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const AuthException('User not found');
      return AuthUserEntity(uid: user.uid, email: user.email ?? '');
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<AuthUserEntity> signUp(String email, String password) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const AuthException('User creation failed');
      return AuthUserEntity(uid: user.uid, email: user.email ?? '');
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }
}
