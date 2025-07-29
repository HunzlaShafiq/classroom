import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileProvider extends ChangeNotifier{

  ProfileProvider(){
    fetchUserData();
  }

  final userId = FirebaseAuth.instance.currentUser!.uid;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userData => _userData;





  Future<void> fetchUserData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("Users3")
          .doc(userId)
          .get();

      if (snapshot.exists) {
          _userData = snapshot.data();
          _setLoading(false);

      }

    } catch (e) {
      print("Failed to fetch user data: $e");
    }
  }

  void updateUserData(userData){
    _userData = userData;
    notifyListeners();

  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

}