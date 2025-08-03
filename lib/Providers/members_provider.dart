import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MemberProvider with ChangeNotifier {
  final String classroomId;
  MemberProvider({required this.classroomId}) {
    _fetchMembers();
  }

  List<Map<String, dynamic>> _membersData = [];
  List<Map<String, dynamic>> get membersData => _membersData;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  void _fetchMembers() {
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
}
