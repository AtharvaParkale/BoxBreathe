import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/usecases/link_anonymous_with_google.dart';
import '../../domain/usecases/sign_in_anonymously.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final SignInAnonymously signInAnonymously;
  final SignInWithGoogle signInWithGoogle;
  final LinkAnonymousWithGoogle linkAnonymousWithGoogle;
  final SignOut signOut;
  final DeleteAccount deleteAccount;

  StreamSubscription<UserProfile?>? _authSubscription;

  AuthBloc({
    required this.authRepository,
    required this.signInAnonymously,
    required this.signInWithGoogle,
    required this.linkAnonymousWithGoogle,
    required this.signOut,
    required this.deleteAccount,
  }) : super(const AuthState()) {
    on<AppStarted>(_onAppStarted);
    on<AuthUserChanged>(_onAuthUserChanged);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));

    await _authSubscription?.cancel();
    _authSubscription = authRepository.authStateChanges.listen(
      (user) => add(AuthUserChanged(user)),
    );

    if (authRepository.currentUser == null) {
      final result = await signInAnonymously();
      result.fold(
        (failure) => emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: failure.message,
          ),
        ),
        (_) {},
      );
    }
  }

  void _onAuthUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    if (user == null) {
      // Signed out from under us (e.g. account deleted). Guest mode is the
      // permanent floor, so re-enter it rather than leaving the app blocked.
      add(AppStarted());
      return;
    }
    emit(
      state.copyWith(
        status: user.provider == AuthProviderType.anonymous
            ? AuthStatus.anonymous
            : AuthStatus.signedIn,
        user: user,
      ),
    );
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = state.status == AuthStatus.anonymous
        ? await linkAnonymousWithGoogle()
        : await signInWithGoogle();
    result.fold(
      (failure) => emit(
        state.copyWith(status: AuthStatus.error, errorMessage: failure.message),
      ),
      (profile) => emit(
        state.copyWith(status: AuthStatus.signedIn, user: profile),
      ),
    );
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await signOut();
    add(AppStarted());
  }

  Future<void> _onDeleteAccountRequested(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await deleteAccount();
    result.fold(
      (failure) => emit(
        state.copyWith(status: AuthStatus.error, errorMessage: failure.message),
      ),
      (_) => add(AppStarted()),
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
