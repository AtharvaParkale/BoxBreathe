import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';

abstract class AuthRepository {
  Stream<UserProfile?> get authStateChanges;
  UserProfile? get currentUser;

  Future<Either<Failure, UserProfile>> signInAnonymously();
  Future<Either<Failure, UserProfile>> signInWithGoogle();
  Future<Either<Failure, UserProfile>> linkAnonymousWithGoogle();
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, void>> deleteAccount();
}
