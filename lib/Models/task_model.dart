import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final int marks;
  final String fileName;
  final String? fileUrl;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.marks,
    required this.fileName,
    this.fileUrl,
  });

  factory TaskModel.fromFirestore(Map<String, dynamic> data, String id) {
    return TaskModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      fileName: data['fileName'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      marks: data['marks'] ?? 0,
      fileUrl: data['fileUrl'],
    );
  }
}