import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../Models/task_model.dart';

class TaskProvider with ChangeNotifier {
  final String classroomId;
  TaskProvider({required this.classroomId}) {
    fetchClassDetails();
  }

  List<TaskModel> _tasks = [];
  List<TaskModel> get tasks => _tasks;

  List<Map<String, dynamic>> _membersData = [];
  List<Map<String, dynamic>> get membersData => _membersData;


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

  Future<void> _fetchMembers() async{
    FirebaseFirestore.instance
        .collection("Classrooms")
        .doc(classroomId)
        .snapshots()
        .listen((doc) async {
      final memberIds = (doc.data()?['members'] ?? []) as List;
      final futures = memberIds.map((id) => FirebaseFirestore.instance.collection("Users3").doc(id).get());
      final results = await Future.wait(futures);
      _membersData = results.map((e) => e.data()!..['id'] = e.id).toList();
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
