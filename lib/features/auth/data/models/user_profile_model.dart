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
      provider: user.isAnonymous
          ? AuthProviderType.anonymous
          : AuthProviderType.google,
      createdAt: user.metadata.creationTime ?? now,
      lastActiveAt: now,
    );
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
      provider: data['provider'] == 'google'
          ? AuthProviderType.google
          : AuthProviderType.anonymous,
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
      'provider': provider == AuthProviderType.google
          ? 'google'
          : 'anonymous',
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'onboardingComplete': onboardingComplete,
    };
  }
}
