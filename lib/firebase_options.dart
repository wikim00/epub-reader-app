// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return FirebaseOptions(
      apiKey: 'AIzaSyDo6GcLiFux0WnkwI9b0LuxMn4_-z-J1XM',
      authDomain: 'epub-reader-8f1e2.firebaseapp.com',
      projectId: 'epub-reader-8f1e2',
      storageBucket: 'epub-reader-8f1e2.firebasestorage.app',
      messagingSenderId: '1058580536468',
      appId: '1:1058580536468:web:1143d70621599b9b05e881',
      measurementId: 'G-5BSLZVCMP9',
    );
  }
}
