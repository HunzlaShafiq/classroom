import 'package:classroom/Screens/HomeScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AuthProviders extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> login(String email, String password, BuildContext context) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Fluttertoast.showToast(msg: "Login Successful!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          Fluttertoast.showToast(msg: "The email address is badly formatted.");
          break;
        case 'user-disabled':
          Fluttertoast.showToast(msg: "This user account has been disabled.");
          break;
        case 'user-not-found':
          Fluttertoast.showToast(msg: "No user found for that email.");
          break;
        case 'wrong-password':
          Fluttertoast.showToast(msg: "Incorrect password.");
          break;
        default:
          Fluttertoast.showToast(msg: "Login failed. ${e.message}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Something went wrong. Please try again.");
    } finally {
      _setLoading(false);
    }
  }


  Future<void> signup({
    required String username,
    required String phone,
    required String email,
    required String password,
    required BuildContext context,
  }) async
  {
    _setLoading(true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance.collection("Users3").doc(cred.user!.uid).set({
        "username": username,
        "phone": phone,
        "email": email,
        "createdAt": Timestamp.now(),
      });

      Fluttertoast.showToast(msg: "Account Created!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          Fluttertoast.showToast(msg: "This email is already registered.");
          break;
        case 'invalid-email':
          Fluttertoast.showToast(msg: "Please enter a valid email.");
          break;
        case 'operation-not-allowed':
          Fluttertoast.showToast(msg: "Operation not allowed. Please contact support.");
          break;
        case 'weak-password':
          Fluttertoast.showToast(msg: "Password is too weak.");
          break;
        default:
          Fluttertoast.showToast(msg: "Signup failed. ${e.message}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Something went wrong. Please try again.");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword({required String email,context}) async {
    _setLoading(true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.trim(),
      );
      Fluttertoast.showToast(msg: "Password reset link sent!");
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? "Failed to send reset link");
    } finally {
      _setLoading(false);
    }
  }



  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
