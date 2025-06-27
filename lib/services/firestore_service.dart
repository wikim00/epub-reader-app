import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final _firestore = FirebaseFirestore.instance;
  static final _user = FirebaseAuth.instance.currentUser;

  static Future<void> saveLocation(String bookId, String cfi) async {
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('books')
        .doc(bookId)
        .set({'cfi': cfi, 'updatedAt': FieldValue.serverTimestamp()});
  }

  static Future<String?> getLastLocation(String bookId) async {
    final doc = await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('books')
        .doc(bookId)
        .get();

    return doc.exists ? doc.data()?['cfi'] as String? : null;
  }
}
