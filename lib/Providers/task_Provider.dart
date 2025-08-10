import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../Models/task_model.dart';

class TaskProvider with ChangeNotifier {
  final String classroomId;
  TaskProvider({required this.classroomId}) {
    fetchClassDetails();
  }

  List<TaskModel> _tasks = [];
  List<TaskModel> get tasks => _tasks;

  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _students = [];

  List<Map<String, dynamic>> get teachers => _teachers;
  List<Map<String, dynamic>> get students => _students;



  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchClassDetails() async{
    Future.wait([
      _listenToTasks(),
      _fetchMembers()
    ]);
  }

  Future<void> _listenToTasks() async {
    FirebaseFirestore.instance
        .collection("Classrooms")
        .doc(classroomId)
        .collection("Tasks")
        .orderBy("dueDate")
        .snapshots()
        .listen((snapshot) {
      _tasks = snapshot.docs.map((doc) => TaskModel.fromFirestore(doc.data(), doc.id)).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }



  Future<void> _fetchMembers() async {
    FirebaseFirestore.instance
        .collection("Classrooms")
        .doc(classroomId)
        .snapshots()
        .listen((doc) async {
      if (!doc.exists) return;

      final data = doc.data()!;
      final memberIds = (data['members'] ?? []) as List;
      final createdById = data['createdBy']; // Teacher's user ID

      // Fetch all member user docs
      final futures = memberIds
          .map((id) => FirebaseFirestore.instance.collection("Users3").doc(id).get());
      final results = await Future.wait(futures);

      // Separate into teacher and students
      _teachers = [];
      _students = [];
      for (var e in results) {
        final userData = e.data()!..['id'] = e.id;
        if (e.id == createdById) {
          _teachers.add(userData);
        } else {
          _students.add(userData);
        }
      }

      _isLoading = false;
      notifyListeners();
    });
  }


  Future<void> deleteTask(String taskId, String? fileUrl) async {
    try {
      // Delete the file from Firebase Storage if a URL is provided
      if (fileUrl != null && fileUrl.isNotEmpty) {
        final storageRef = FirebaseStorage.instance.refFromURL(fileUrl);
        await storageRef.delete();
      }

      // Delete the task document from Firestore
      await FirebaseFirestore.instance
          .collection("Classrooms")
          .doc(classroomId)
          .collection("Tasks")
          .doc(taskId)
          .delete();
    } catch (e) {
      debugPrint(" Error deleting task or file: $e");
      rethrow;
    }
  }

}
