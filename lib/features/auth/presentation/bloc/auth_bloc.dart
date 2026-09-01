import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/usecases/link_anonymous_with_google.dart';
import '../../domain/usecases/sign_in_anonymously.dart';
import '../../domain/usecases/sign_in_with_email_password.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up_with_email_password.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final SignInAnonymously signInAnonymously;
  final SignInWithGoogle signInWithGoogle;
  final SignInWithEmailPassword signInWithEmailPassword;
  final SignUpWithEmailPassword signUpWithEmailPassword;
  final LinkAnonymousWithGoogle linkAnonymousWithGoogle;
  final SignOut signOut;
  final DeleteAccount deleteAccount;

  StreamSubscription<UserProfile?>? _authSubscription;

  AuthBloc({
    required this.authRepository,
    required this.signInAnonymously,
    required this.signInWithGoogle,
    required this.signInWithEmailPassword,
    required this.signUpWithEmailPassword,
    required this.linkAnonymousWithGoogle,
    required this.signOut,
    required this.deleteAccount,
  }) : super(const AuthState()) {
    on<AppStarted>(_onAppStarted);
    on<AuthUserChanged>(_onAuthUserChanged);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<EmailSignInRequested>(_onEmailSignInRequested);
    on<EmailSignUpRequested>(_onEmailSignUpRequested);
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
      // authStateChanges replays the current (null) value the moment
      // _onAppStarted subscribes, before the in-flight anonymous sign-in
      // resolves. Only re-trigger AppStarted if we were previously
      // authenticated and got signed out from under us (e.g. account
      // deleted) — otherwise this loops with _onAppStarted forever and
      // hangs the app.
      if (state.status == AuthStatus.signedIn ||
          state.status == AuthStatus.anonymous) {
        add(AppStarted());
      }
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

  Future<void> _onEmailSignInRequested(
    EmailSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await signInWithEmailPassword(event.email, event.password);
    result.fold(
      (failure) => emit(
        state.copyWith(status: AuthStatus.error, errorMessage: failure.message),
      ),
      (profile) => emit(
        state.copyWith(status: AuthStatus.signedIn, user: profile),
      ),
    );
  }

  Future<void> _onEmailSignUpRequested(
    EmailSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await signUpWithEmailPassword(event.email, event.password);
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
