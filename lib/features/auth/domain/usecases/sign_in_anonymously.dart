import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class SignInAnonymously {
  final AuthRepository repository;

  SignInAnonymously(this.repository);

  Future<Either<Failure, UserProfile>> call() async {
    return await repository.signInAnonymously();
  }
}
