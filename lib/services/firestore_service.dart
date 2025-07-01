import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final _firestore = FirebaseFirestore.instance;

  static User? get _user => FirebaseAuth.instance.currentUser;

  // Save chapter index as integer
  static Future<void> saveLocation(String bookId, int chapterIndex) async {
    final user = _user;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('books')
        .doc(bookId)
        .set({
      'chapterIndex': chapterIndex,
      'updatedAt': FieldValue.serverTimestamp()
    });
  }

  // Get last chapter index as integer
  static Future<int?> getLastLocation(String bookId) async {
    final user = _user;
    if (user == null) return null;
    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('books')
        .doc(bookId)
        .get();

    if (doc.exists) {
      final data = doc.data();
      return data?['chapterIndex'] as int?;
    }
    return null;
  }
}
