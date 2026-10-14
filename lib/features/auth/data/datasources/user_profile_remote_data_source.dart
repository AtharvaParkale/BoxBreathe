import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../../core/error/exceptions.dart';
import '../models/user_profile_model.dart';

abstract class UserProfileRemoteDataSource {
  /// Reads `users/{uid}`, creating it on first sign-in. On an existing doc,
  /// refreshes provider-sourced fields (name/email/photo/provider) and
  /// touches `lastActiveAt`, preserving `createdAt` and `onboardingComplete`.
  Future<UserProfileModel> getOrCreateProfile(firebase_auth.User user);

  /// Deletes `users/{uid}` and its `sessions` subcollection. Must run while
  /// the user is still signed in — Firestore rules require `request.auth`.
  Future<void> deleteProfile(String uid);
}

class UserProfileFirestoreDataSourceImpl implements UserProfileRemoteDataSource {
  final FirebaseFirestore firestore;

  UserProfileFirestoreDataSourceImpl({required this.firestore});

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      firestore.collection('users').doc(uid);

  @override
  Future<UserProfileModel> getOrCreateProfile(
    firebase_auth.User user,
  ) async {
    try {
      final docRef = _doc(user.uid);
      final snapshot = await docRef.get();
      final data = snapshot.data();

      final UserProfileModel profile;
      if (snapshot.exists && data != null) {
        final existing = UserProfileModel.fromFirestore(data, user.uid);
        profile = UserProfileModel(
          uid: existing.uid,
          displayName: user.displayName ?? existing.displayName,
          email: user.email ?? existing.email,
          photoUrl: user.photoURL ?? existing.photoUrl,
          provider: UserProfileModel.providerFromFirebaseUser(user),
          createdAt: existing.createdAt,
          lastActiveAt: DateTime.now(),
          onboardingComplete: existing.onboardingComplete,
        );
      } else {
        profile = UserProfileModel.fromFirebaseUser(user);
      }

      await docRef.set(profile.toFirestore(), SetOptions(merge: true));
      return profile;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteProfile(String uid) async {
    try {
      final sessions = await _doc(uid).collection('sessions').get();
      // Firestore batches cap at 500 writes.
      for (var i = 0; i < sessions.docs.length; i += 500) {
        final batch = firestore.batch();
        for (final doc in sessions.docs.skip(i).take(500)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      await _doc(uid).delete();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
