import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn? googleSignIn = kIsWeb ? null : GoogleSignIn();

  // GOOGLE SIGN IN
  Future<User?> signInWithGoogle() async {
    if (kIsWeb) {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      UserCredential userCredential =
          await _auth.signInWithPopup(googleProvider);
      return userCredential.user;
    } else {
      final googleUser = await googleSignIn?.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return (await _auth.signInWithCredential(credential)).user;
    }
  }

  // EMAIL/PASSWORD REGISTER
  // Throws FirebaseAuthException so the caller can show the real reason
  // (weak password, email already in use, ...) instead of failing silently.
  Future<User?> registerWithEmail(String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  // EMAIL/PASSWORD LOGIN
  Future<User?> signInWithEmail(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  // SIGN OUT
  Future<void> signOut() async {
    if (!kIsWeb) {
      await googleSignIn?.signOut();
    }
    await _auth.signOut();
  }

  // AUTH STATE STREAM
  Stream<User?> get userStream => _auth.authStateChanges();
}
