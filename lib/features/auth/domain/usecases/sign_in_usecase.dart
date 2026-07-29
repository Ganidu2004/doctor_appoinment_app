import 'package:appoinment_app/core/usecase/usecase.dart';
import 'package:appoinment_app/features/auth/domain/entities/auth_user_entity.dart';
import 'package:appoinment_app/features/auth/domain/repositories/auth_repository.dart';

class SignInParams {
  final String email;
  final String password;
  const SignInParams({required this.email, required this.password});
}

class SignInUseCase implements UseCase<AuthUserEntity, SignInParams> {
  final AuthRepository repository;
  SignInUseCase(this.repository);

  @override
  Future<AuthUserEntity> call(SignInParams params) {
    return repository.signInWithEmailAndPassword(params.email, params.password);
  }
}
