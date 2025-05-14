
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInProvider {
  static final _googleSignIn = GoogleSignIn(
  clientId: '51124256983-71l75j897r7s1m2n0d55lqo5q5fgqnnn.apps.googleusercontent.com', // reemplaza con el tuyo real
);
  static final _auth = FirebaseAuth.instance;

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Error en Google Sign-In: $e');
      return null;
    }
  }
}
