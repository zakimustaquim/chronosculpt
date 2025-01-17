import 'package:chronosculpt/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Handles user authentication using Firebase.
class FirebaseHelper {
  final _fa = FirebaseAuth.instance;

  Future<UserCredential?> createUser(
      String email, String pass, BuildContext context) async {
    UserCredential? credential;
    try {
      credential = await _fa.createUserWithEmailAndPassword(
          email: email, password: pass);
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, _mapFirebaseAuthException(e));
    } catch (e) {
      showSnackBar(context, 'Unknown error: $e');
    }
    return credential;
  }

  String _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'Please enter a valid email.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'wrong-password':
        return 'The wrong password was entered.';
      case 'user-not-found':
        return "No account was found with that email.";
      case 'missing-password':
        return "Please enter a password.";
      case 'invalid-credential':
        return "The credentials could not be authenticated.";
      case 'user-mismatch':
        return 'The credentials could not be authenticated.';
      default:
        return 'Unknown error: ${e.code}';
    }
  }

  Future<UserCredential?> logIn(
      String email, String pass, BuildContext context) async {
    UserCredential? credential;
    try {
      credential =
          await _fa.signInWithEmailAndPassword(email: email, password: pass);
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, _mapFirebaseAuthException(e));
    } catch (e) {
      showSnackBar(context, 'Unknown error: $e');
    }
    return credential;
  }

  Future<void> signOut() async => await _fa.signOut();

  bool authenticated() => _fa.currentUser != null;

  Future<void> resetPassword(String email, BuildContext context) async {
    try {
      await _fa.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (fae) {
      showSnackBar(context, _mapFirebaseAuthException(fae));
    } catch (e) {
      showSnackBar(context, 'Unknown error: $e');
    }
  }

  Future<void> updateCurrentUserEmail(String email, String password, BuildContext context) async {
    try {
      var currentUser = _fa.currentUser;
      if (currentUser == null) return;
      currentUser.reauthenticateWithCredential(EmailAuthProvider.credential(email: currentUser.email!, password: password));
      currentUser.verifyBeforeUpdateEmail('email');
    } on FirebaseAuthException catch (fae) {
      showSnackBar(context, _mapFirebaseAuthException(fae));
    } catch (e) {
      showSnackBar(context, 'Unknown error: $e');
    }
  }

  Future<void> updateCurrentUserPassword(String oldPassword, String newPassword, BuildContext context) async {
    try {
      var currentUser = _fa.currentUser;
      if (currentUser == null) return;
      currentUser.reauthenticateWithCredential(EmailAuthProvider.credential(email: currentUser.email!, password: oldPassword));
      currentUser.updatePassword(newPassword);
    } on FirebaseAuthException catch (fae) {
      showSnackBar(context, _mapFirebaseAuthException(fae));
    } catch (e) {
      showSnackBar(context, 'Unknown error: $e');
    }
  }
}
