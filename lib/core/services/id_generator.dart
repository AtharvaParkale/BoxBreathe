import 'package:cloud_firestore/cloud_firestore.dart';

/// Mints a client-side-unique id, shared between a session's local record
/// and its Firestore mirror so sync can dedup by identity.
abstract class IdGenerator {
  String newId();
}

/// Backed by Firestore's own id generation, which is entirely client-side
/// (no network round-trip, works fully offline) — reusing it avoids adding
/// a new uuid dependency just for this.
class FirestoreIdGenerator implements IdGenerator {
  final FirebaseFirestore firestore;

  FirestoreIdGenerator(this.firestore);

  @override
  String newId() => firestore.collection('_ids').doc().id;
}
