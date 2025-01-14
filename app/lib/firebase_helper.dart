import 'package:chronosculpt/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseHelper {
  FirebaseAuth fa = FirebaseAuth.instance;

  Future<UserCredential?> createUser(
      String email, String pass, BuildContext context) async {
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
      } else {
        showSnackBar(context, 'Unknown error: ${e.code}');
      }
    } catch (e) {
      showSnackBar(context, 'Unknown error: $e');
    }
    return credential;
  }

  Future<UserCredential?> logIn(
      String email, String pass, BuildContext context) async {
    UserCredential? credential;
    try {
      credential =
          await fa.signInWithEmailAndPassword(email: email, password: pass);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        showSnackBar(context, 'The wrong password was entered.');
      } else if (e.code == 'user-not-found') {
        showSnackBar(context, 'No account was found with that email.');
      } else if (e.code == 'invalid-email') {
        showSnackBar(context, 'Please enter a valid email.');
      } else if (e.code == 'missing-password') {
        showSnackBar(context, 'Please enter a password.');
      } else if (e.code == 'invalid-credential') {
        showSnackBar(context, 'The credentials could not be authenticated.');
      } else {
        showSnackBar(context, 'Unknown error: ${e.code}');
      }
    } catch (e) {
      showSnackBar(context, 'Unknown error: $e');
    }
    return credential;
  }

  Future<void> signOut() async => await fa.signOut();

  bool authenticated() => fa.currentUser != null;
}
