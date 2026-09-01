import 'package:equatable/equatable.dart';

import '../../domain/entities/user_profile.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Dispatched once at app launch. Signs in anonymously if there's no current
/// user, then subscribes to the auth-state stream for the rest of the
/// session. Also re-dispatched internally after sign-out/account deletion so
/// guest mode is always restored — the app is never left fully signed out.
class AppStarted extends AuthEvent {}

class GoogleSignInRequested extends AuthEvent {}

/// Debug-only — see `AccountSection`'s kDebugMode-gated email/password form.
class EmailSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const EmailSignInRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class EmailSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  const EmailSignUpRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class SignOutRequested extends AuthEvent {}

class DeleteAccountRequested extends AuthEvent {}

/// Internal: fed by the auth-state stream subscription, not dispatched by UI.
class AuthUserChanged extends AuthEvent {
  final UserProfile? user;
  const AuthUserChanged(this.user);
  @override
  List<Object?> get props => [user];
}
