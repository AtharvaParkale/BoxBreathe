import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';

abstract class AuthRepository {
  Stream<UserProfile?> get authStateChanges;
  UserProfile? get currentUser;

  Future<Either<Failure, UserProfile>> signInAnonymously();

  /// Debug-only auth path for testing without Google Sign-In — stripped from
  /// the UI (not the codebase) before release. See `AccountSection`.
  Future<Either<Failure, UserProfile>> signInWithEmailAndPassword(
    String email,
    String password,
  );
  Future<Either<Failure, UserProfile>> signUpWithEmailAndPassword(
    String email,
    String password,
  );

  Future<Either<Failure, UserProfile>> signInWithGoogle();
  Future<Either<Failure, UserProfile>> linkAnonymousWithGoogle();
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, void>> deleteAccount();
}
