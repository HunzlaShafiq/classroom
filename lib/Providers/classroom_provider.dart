import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  Future<void> createClassroom(className,classDescription,classImageFile,context) async {


    _setLoading(true);

    try {
      // 1. Upload image (if selected)
      String? classImageURL = await _uploadImage(classImageFile,context);

      // 2. Generate random 6-digit join code
      final joinCode = _generateJoinCode();

      // 3. Save to Firestore
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection("Classrooms").add({
        "className": className.trim(),
        "classDescription":classDescription.trim(),
        "classImageUrl": classImageURL,
        "createdBy": user.uid,
        "createdAt": Timestamp.now(),
        "joinCode": joinCode,
        "members": [user.uid], // Creator is first member
      });

      // 4. Update user's joined classrooms
      await FirebaseFirestore.instance.collection("Users3").doc(user.uid).update({
        "joinedClassrooms": FieldValue.arrayUnion([]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Classroom created!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> _uploadImage(classImage,context) async {
    if (classImage == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("classroom_images/${DateTime.now().millisecondsSinceEpoch}.jpg");
      await ref.putFile(classImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e")),
      );
      return null;
    }
  }

  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }


  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
