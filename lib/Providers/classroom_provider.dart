import 'dart:io';
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

      final String classroomID=DateTime.now().millisecondsSinceEpoch.toString();

      // 1. Upload image (if selected)
      String? classImageURL = await _uploadImage(classImageFile,context,classroomID);

      // 2. Generate random 6-digit join code
      final joinCode = _generateJoinCode();

      // 3. Save to Firestore
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection("Classrooms").doc(classroomID).set({
        'classroomID':classroomID,
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

  Future<String?> _uploadImage(classImage,context,classroomID) async {
    if (classImage == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("classroom_images/$classroomID.jpg");
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

  Future<void> deleteAllTasksAndClassroom(classroomId) async {
    final taskCollection = FirebaseFirestore.instance
        .collection("Classrooms")
        .doc(classroomId)
        .collection("Tasks");

    final tasksSnapshot = await taskCollection.get();

    for (final doc in tasksSnapshot.docs) {
      final data = doc.data();
      final fileUrl = data['fileUrl'] as String?;
      if (fileUrl != null && fileUrl.isNotEmpty) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(fileUrl);
          await ref.delete();
        } catch (e) {
          debugPrint("Error deleting file: $e");
        }
      }
      await doc.reference.delete();
    }

    // Now delete classroom
    await FirebaseFirestore.instance.collection("Classrooms").doc(classroomId).delete();
  }

  Future<void> updateClassroom({
    required String classroomId,
    required String className,
    required String description,
    File? newImageFile,
    String? existingImageUrl,
    required BuildContext context,
  }) async {
    _setLoading(true);

    try {
      String? finalImageUrl = existingImageUrl;

      // If user selected a new image, upload it
      if (newImageFile != null) {
        final imageRef = FirebaseStorage.instance.ref().child("classroom_images/$classroomId.jpg");
        await imageRef.putFile(newImageFile);
        finalImageUrl = await imageRef.getDownloadURL();
      }

      // Prepare updated data
      final Map<String, dynamic> updatedData = {
        "className": className,
        "classDescription": description,
        "imageUrl": finalImageUrl ?? "",
        "updatedAt": FieldValue.serverTimestamp(),
      };

      // Update Firestore
      await FirebaseFirestore.instance.collection("classrooms").doc(classroomId).update(updatedData);

      // Feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Classroom updated successfully")),
      );

      Navigator.pop(context);

    } catch (e) {
      debugPrint("Error updating classroom: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      _setLoading(false);
    }
  }



  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
