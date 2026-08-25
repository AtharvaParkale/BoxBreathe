import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/error/exceptions.dart';

abstract class AuthRemoteDataSource {
  Stream<firebase_auth.User?> get authStateChanges;
  firebase_auth.User? get currentUser;

  Future<firebase_auth.User> signInAnonymously();

  /// Runs the interactive Google account picker and exchanges the result for
  /// a Firebase [firebase_auth.AuthCredential]. Does not touch Firebase Auth
  /// state itself — callers decide whether to sign in or link with it.
  Future<firebase_auth.AuthCredential> getGoogleCredential();

  Future<firebase_auth.User> signInWithCredential(
    firebase_auth.AuthCredential credential,
  );

  /// Links [credential] to the currently signed-in user. Throws
  /// [AuthException] with code `credential-already-in-use` if that Google
  /// account is already tied to a different Firebase user.
  Future<firebase_auth.User> linkCurrentUserWithCredential(
    firebase_auth.AuthCredential credential,
  );

  Future<void> signOut();
  Future<void> deleteAccount();
}

class FirebaseAuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;

  bool _googleSignInInitialized = false;

  FirebaseAuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.googleSignIn,
  });

  @override
  Stream<firebase_auth.User?> get authStateChanges =>
      firebaseAuth.authStateChanges();

  @override
  firebase_auth.User? get currentUser => firebaseAuth.currentUser;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await googleSignIn.initialize();
    _googleSignInInitialized = true;
  }

  @override
  Future<firebase_auth.AuthCredential> getGoogleCredential() async {
    await _ensureGoogleSignInInitialized();
    if (!googleSignIn.supportsAuthenticate()) {
      throw const AuthException(
        'Google Sign-In is not supported on this platform',
        'unsupported-platform',
      );
    }
    try {
      final account = await googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException(
          'Google Sign-In did not return an ID token',
          'missing-id-token',
        );
      }
      return firebase_auth.GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      throw AuthException(
        e.description ?? 'Google Sign-In failed',
        e.code.name,
      );
    }
  }

  @override
  Future<firebase_auth.User> signInAnonymously() async {
    try {
      final credential = await firebaseAuth.signInAnonymously();
      return _requireUser(credential.user, 'Anonymous sign-in');
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Anonymous sign-in failed', e.code);
    }
  }

  @override
  Future<firebase_auth.User> signInWithCredential(
    firebase_auth.AuthCredential credential,
  ) async {
    try {
      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );
      return _requireUser(userCredential.user, 'Google sign-in');
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Google sign-in failed', e.code);
    }
  }

  @override
  Future<firebase_auth.User> linkCurrentUserWithCredential(
    firebase_auth.AuthCredential credential,
  ) async {
    final current = firebaseAuth.currentUser;
    if (current == null) {
      throw const AuthException(
        'No signed-in user to link',
        'no-current-user',
      );
    }
    try {
      final userCredential = await current.linkWithCredential(credential);
      return _requireUser(userCredential.user, 'Account linking');
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Account linking failed', e.code);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
      await googleSignIn.signOut();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Sign out failed', e.code);
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException(
        'No signed-in user to delete',
        'no-current-user',
      );
    }
    try {
      await user.delete();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Account deletion failed', e.code);
    }
  }

  firebase_auth.User _requireUser(firebase_auth.User? user, String action) {
    if (user == null) {
      throw AuthException('$action returned no user', 'null-user');
    }
    return user;
  }
}
