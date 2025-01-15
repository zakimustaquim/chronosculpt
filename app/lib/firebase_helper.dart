import 'package:chronosculpt/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseHelper {
  FirebaseAuth fa = FirebaseAuth.instance;

  Future<UserCredential?> createUser(String email, String pass, BuildContext context) async {
    UserCredential? credential;
    try {
      credential =
          await fa.createUserWithEmailAndPassword(email: email, password: pass);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        showSnackBar(context, 'The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        showSnackBar(context, 'The account already exists for that email.');
      } else if (e.code == 'invalid-email') {
        showSnackBar(context, 'Please enter a valid email.');
      }
    } catch (e) {
      showSnackBar(context, 'Unknown error: $e');
    }
    return credential;
  }

  Future<void> signOut() async => await fa.signOut();

  bool authenticated() {
    return fa.currentUser != null;
  }
}
