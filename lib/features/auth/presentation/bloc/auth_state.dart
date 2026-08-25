import 'package:equatable/equatable.dart';

import '../../domain/entities/user_profile.dart';

enum AuthStatus { initial, loading, anonymous, signedIn, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserProfile? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: status == AuthStatus.error ? errorMessage : null,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}
