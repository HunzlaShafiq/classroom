import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClassroomProvider extends ChangeNotifier {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  ClassroomProvider() {
    _listenToClassrooms();
  }

  bool _isLoading = true;
  List<DocumentSnapshot> _classrooms = [];

  bool get isLoading => _isLoading;
  List<DocumentSnapshot> get classrooms => _classrooms;

  void _listenToClassrooms() {
    FirebaseFirestore.instance
        .collection("Classrooms")
        .where("members", arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
      _classrooms = snapshot.docs;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      _isLoading = false;
      notifyListeners();
    });
  }
}
