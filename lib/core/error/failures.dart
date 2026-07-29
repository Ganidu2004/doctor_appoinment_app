abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server Error Occurred']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache Error Occurred']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication Error Occurred']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation Failed']);
}
