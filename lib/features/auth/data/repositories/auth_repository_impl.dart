import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/user_profile_remote_data_source.dart';
import '../models/user_profile_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource authRemoteDataSource;
  final UserProfileRemoteDataSource userProfileRemoteDataSource;

  AuthRepositoryImpl({
    required this.authRemoteDataSource,
    required this.userProfileRemoteDataSource,
  });

  @override
  Stream<UserProfile?> get authStateChanges => authRemoteDataSource
      .authStateChanges
      .map((user) => user == null ? null : UserProfileModel.fromFirebaseUser(user));

  @override
  UserProfile? get currentUser {
    final user = authRemoteDataSource.currentUser;
    return user == null ? null : UserProfileModel.fromFirebaseUser(user);
  }

  @override
  Future<Either<Failure, UserProfile>> signInAnonymously() async {
    try {
      final user = await authRemoteDataSource.signInAnonymously();
      final profile = await userProfileRemoteDataSource.getOrCreateProfile(
        user,
      );
      return Right(profile);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final user = await authRemoteDataSource.signInWithEmailAndPassword(
        email,
        password,
      );
      final profile = await userProfileRemoteDataSource.getOrCreateProfile(
        user,
      );
      return Right(profile);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final user = await authRemoteDataSource.createUserWithEmailAndPassword(
        email,
        password,
      );
      final profile = await userProfileRemoteDataSource.getOrCreateProfile(
        user,
      );
      return Right(profile);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> signInWithGoogle() async {
    try {
      final credential = await authRemoteDataSource.getGoogleCredential();
      final user = await authRemoteDataSource.signInWithCredential(
        credential,
      );
      final profile = await userProfileRemoteDataSource.getOrCreateProfile(
        user,
      );
      return Right(profile);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> linkAnonymousWithGoogle() async {
    try {
      final credential = await authRemoteDataSource.getGoogleCredential();
      final isAnonymous = authRemoteDataSource.currentUser?.isAnonymous ?? false;

      firebase_auth.User user;
      if (isAnonymous) {
        try {
          user = await authRemoteDataSource.linkCurrentUserWithCredential(
            credential,
          );
        } on AuthException catch (e) {
          if (e.code != 'credential-already-in-use') rethrow;
          // The Google account is already tied to a different Firebase user
          // (e.g. signed in from another device first). We can't merge two
          // independent session histories automatically, so fall back to
          // signing into that existing account — this device's pre-link
          // anonymous history stays local-only/unsynced. Deliberate, not a
          // bug: see plan risks.
          user = await authRemoteDataSource.signInWithCredential(credential);
        }
      } else {
        user = await authRemoteDataSource.signInWithCredential(credential);
      }

      final profile = await userProfileRemoteDataSource.getOrCreateProfile(
        user,
      );
      return Right(profile);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await authRemoteDataSource.signOut();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      final uid = authRemoteDataSource.currentUser?.uid;
      await authRemoteDataSource.deleteAccount();
      if (uid != null) {
        await userProfileRemoteDataSource.deleteProfile(uid);
      }
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
