import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../Models/task_model.dart';

class TaskProvider with ChangeNotifier {
  final String classroomId;
  TaskProvider({required this.classroomId}) {
    _listenToTasks();
  }

  List<TaskModel> _tasks = [];
  List<TaskModel> get tasks => _tasks;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void _listenToTasks() {
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

  Future<void> deleteTask(String taskId) async {
    await FirebaseFirestore.instance
        .collection("Classrooms")
        .doc(classroomId)
        .collection("Tasks")
        .doc(taskId)
        .delete();
  }
}
