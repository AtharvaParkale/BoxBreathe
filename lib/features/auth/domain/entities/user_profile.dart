import 'package:equatable/equatable.dart';

enum AuthProviderType { anonymous, google, email }

class UserProfile extends Equatable {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final AuthProviderType provider;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final bool onboardingComplete;

  const UserProfile({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    required this.provider,
    required this.createdAt,
    required this.lastActiveAt,
    this.onboardingComplete = false,
  });

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    AuthProviderType? provider,
    DateTime? lastActiveAt,
    bool? onboardingComplete,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    displayName,
    email,
    photoUrl,
    provider,
    createdAt,
    lastActiveAt,
    onboardingComplete,
  ];
}
