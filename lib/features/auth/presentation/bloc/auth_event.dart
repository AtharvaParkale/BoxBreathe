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

class SignOutRequested extends AuthEvent {}

class DeleteAccountRequested extends AuthEvent {}

/// Internal: fed by the auth-state stream subscription, not dispatched by UI.
class AuthUserChanged extends AuthEvent {
  final UserProfile? user;
  const AuthUserChanged(this.user);
  @override
  List<Object?> get props => [user];
}
