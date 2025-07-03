import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class LoginPage extends StatelessWidget {
  final VoidCallback onLoginSuccess;
  const LoginPage({Key? key, required this.onLoginSuccess}) : super(key: key);

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      if (kIsWeb) {
        // Web sign-in
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(authProvider);
      } else {
        // Android/iOS sign-in
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return; // User canceled
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      // Optionally show a success message or navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in with Google!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () => signInWithGoogle(context),
              icon: const Icon(Icons.login),
              label: const Text("Sign in with Google"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              child: const Text("Sign out"),
            ),
          ],
        ),
      ),
    );
  }
}
