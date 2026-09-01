import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.uid,
    super.displayName,
    super.email,
    super.photoUrl,
    required super.provider,
    required super.createdAt,
    required super.lastActiveAt,
    super.onboardingComplete,
  });

  factory UserProfileModel.fromFirebaseUser(firebase_auth.User user) {
    final now = DateTime.now();
    return UserProfileModel(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
      provider: providerFromFirebaseUser(user),
      createdAt: user.metadata.creationTime ?? now,
      lastActiveAt: now,
    );
  }

  /// `password`-provider check must come before the `isAnonymous` fallback:
  /// once linked, a Firebase user is no longer anonymous but has no other
  /// provider hook here besides `google.com`/`password`.
  static AuthProviderType providerFromFirebaseUser(firebase_auth.User user) {
    if (user.isAnonymous) return AuthProviderType.anonymous;
    final hasPasswordProvider = user.providerData.any(
      (info) => info.providerId == 'password',
    );
    return hasPasswordProvider ? AuthProviderType.email : AuthProviderType.google;
  }

  factory UserProfileModel.fromFirestore(
    Map<String, dynamic> data,
    String uid,
  ) {
    return UserProfileModel(
      uid: uid,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      photoUrl: data['photoUrl'] as String?,
      provider: switch (data['provider']) {
        'google' => AuthProviderType.google,
        'email' => AuthProviderType.email,
        _ => AuthProviderType.anonymous,
      },
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt:
          (data['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      onboardingComplete: data['onboardingComplete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'provider': switch (provider) {
        AuthProviderType.google => 'google',
        AuthProviderType.email => 'email',
        AuthProviderType.anonymous => 'anonymous',
      },
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'onboardingComplete': onboardingComplete,
    };
  }
}
