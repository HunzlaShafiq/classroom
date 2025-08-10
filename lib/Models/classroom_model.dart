import 'package:cloud_firestore/cloud_firestore.dart';

class Classroom {
  final String classroomId;
  final String className;
  final String classDescription;
  final String classImageUrl;
  final String createdBy;
  final Timestamp createdAt;
  final String joinCode;
  final List<String> members;

  Classroom({
    required this.classroomId,
    required this.className,
    required this.classDescription,
    required this.classImageUrl,
    required this.createdBy,
    required this.createdAt,
    required this.joinCode,
    required this.members,
  });

  // From Firestore Document
  factory Classroom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Classroom(
      classroomId: data['classroomId'] ?? '',
      className: data['className'] ?? '',
      classDescription: data['classDescription'] ?? '',
      classImageUrl: data['classImageUrl'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      joinCode: data['joinCode'] ?? '',
      members: List<String>.from(data['members'] ?? []),
    );
  }

  // To Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'classroomId': classroomId,
      'className': className,
      'classDescription': classDescription,
      'classImageUrl': classImageUrl,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'joinCode': joinCode,
      'members': members,
    };
  }
}
