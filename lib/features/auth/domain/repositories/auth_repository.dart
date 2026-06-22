import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> signInWithApple();

  Future<Either<Failure, void>> signOut();

  Future<bool> isAuthenticated();

  Future<String?> getCurrentUserId();

  Future<String?> getCurrentEmail();
}
