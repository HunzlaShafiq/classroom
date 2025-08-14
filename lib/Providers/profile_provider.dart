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
  String _ProfileLetter='';

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userData => _userData;
  String get profileLetter => _ProfileLetter;





  Future<void> fetchUserData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("Users3")
          .doc(userId)
          .get();

      if (snapshot.exists) {
          _userData = snapshot.data();
          final username = _userData?['username']?.toString().trim() ?? "";
          final nameLetter = username.split(' ').where((e) => e.isNotEmpty).toList();
          if(nameLetter.length>1){
            _ProfileLetter="${nameLetter.first[0]}${nameLetter.last[0]}";
          }
          else{
            _ProfileLetter=nameLetter[0][0];
          }
          _setLoading(false);

      }

    } catch (e) {
      print("Failed to fetch user data: $e");
    }
  }

  void updateUserData(userData){
    fetchUserData();
    notifyListeners();

  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void removeDataOnLogout(){
    _userData?.clear();
    _ProfileLetter='';
    notifyListeners();
  }

  void refreshDataOnLogin(){
    fetchUserData();
  }

}