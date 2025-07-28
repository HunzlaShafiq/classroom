import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;
  final String classroomId;
  final bool isModerator;
  const TaskDetailsScreen({
    super.key,
    required this.taskId,
    required this.classroomId,
    required this.isModerator,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final user = FirebaseAuth.instance.currentUser!;

  Future<void> _downloadFile(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch download")),
      );
    }
  }

  void _gradeSubmission(BuildContext context, QueryDocumentSnapshot submission) {
    final _marksController = TextEditingController(
      text: submission["marksObtained"]?.toString() ?? "",
    );
    final _feedbackController = TextEditingController(
      text: submission["feedback"] ?? "",
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Grade Submission"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _marksController,
                decoration: const InputDecoration(
                  labelText: "Marks",
                  hintText: "Enter marks obtained",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _feedbackController,
                decoration: const InputDecoration(
                  labelText: "Feedback",
                  hintText: "Optional feedback",
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_marksController.text.isEmpty) return;

                try {
                  await submission.reference.update({
                    "marksObtained": int.parse(_marksController.text),
                    "feedback": _feedbackController.text,
                    "isGraded": true,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Submission graded!")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              },
              child: const Text("Submit Grade"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Task Details", style: GoogleFonts.poppins()),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("Classrooms")
            .doc(widget.classroomId)
            .collection("Tasks")
            .doc(widget.taskId)
            .snapshots(),
        builder: (context, taskSnapshot) {
          if (!taskSnapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final task = taskSnapshot.data!;
          final dueDate = task["dueDate"].toDate();
          final isOverdue = dueDate.isBefore(DateTime.now());
          final daysRemaining = dueDate.difference(DateTime.now()).inDays;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Task Overview Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.assignment, color: Colors.deepPurple),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task["title"],
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          task["description"],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            _buildInfoChip(
                              icon: Icons.timer,
                              text: isOverdue
                                  ? "Overdue"
                                  : "$daysRemaining days left",
                              color: isOverdue ? Colors.red : Colors.blue,
                            ),
                            SizedBox(width: 8),
                            _buildInfoChip(
                              icon: Icons.star,
                              text: "${task["marks"]} points",
                              color: Colors.amber,
                            ),

                          ],
                        ),
                        if (task["fileUrl"] != null) ...[
                          SizedBox(width: 8),
                          _buildInfoChip(
                            icon: Icons.attach_file,
                            text: "Attachment",
                            color: Colors.green,
                          ),
                        ],
                        if (task["fileUrl"] != null) ...[
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _downloadFile(task["fileUrl"]),
                            icon: Icon(Icons.download),
                            label: Text("Download Task File"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Conditional rendering based on user role
                if (widget.isModerator)
                  _ModeratorView(
                    taskId: widget.taskId,
                    classroomId: widget.classroomId,
                    onGrade: _gradeSubmission,
                    totalMarks: task["marks"],
                  )
                else
                  _StudentView(
                    taskId: widget.taskId,
                    classroomId: widget.classroomId,
                    totalMarks: task["marks"],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Chip(
      backgroundColor: color.withOpacity(0.2),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 4),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _ModeratorView extends StatelessWidget {
  final String taskId;
  final String classroomId;
  final int totalMarks;
  final Function(BuildContext, QueryDocumentSnapshot) onGrade;

  const _ModeratorView({
    required this.taskId,
    required this.classroomId,
    required this.onGrade,
    required this.totalMarks,
  });

  Future<void> _downloadFile(BuildContext context, String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch download';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            "Submissions",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("Classrooms")
              .doc(classroomId)
              .collection("Tasks")
              .doc(taskId)
              .collection("Submissions")
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (snapshot.data!.docs.isEmpty) {
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "No submissions yet",
                    style: GoogleFonts.poppins(),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final submission = snapshot.data!.docs[index];
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection("Users3")
                      .doc(submission["studentId"])
                      .get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return Card(
                        child: ListTile(
                          title: Text("Loading..."),
                        ),
                      );
                    }

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple.shade100,
                                child: Text(
                                  userSnapshot.data!["username"][0],
                                  style: TextStyle(color: Colors.deepPurple),
                                ),
                              ),
                              title: Text(
                                userSnapshot.data!["username"],
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    submission["fileUrl"].split('/').last,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Submitted: ${DateFormat('MMM dd, hh:mm a').format(submission["submittedAt"].toDate())}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.download, color: Colors.deepPurple),
                                    onPressed: () => _downloadFile(context, submission["fileUrl"]),
                                    tooltip: 'Download submission',
                                  ),
                                  if (submission["isGraded"])
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => onGrade(context, submission),
                                      tooltip: 'Edit grade',
                                    )
                                  else
                                    ElevatedButton(
                                      onPressed: () => onGrade(context, submission),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepPurple,
                                        padding: EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                      child: Text("Grade"),
                                    ),
                                ],
                              ),
                            ),
                            if (submission["isGraded"]) ...[
                              Divider(),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Icon(Icons.grade, color: Colors.amber),
                                    SizedBox(width: 8),
                                    Text(
                                      "${submission["marksObtained"]}/$totalMarks",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getGradeColor(
                                          submission["marksObtained"],
                                          totalMarks,
                                        ),
                                      ),
                                    ),
                                    if (submission["feedback"] != null) ...[
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          '"${submission["feedback"]}"',
                                          style: TextStyle(fontStyle: FontStyle.italic),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Color _getGradeColor(int marks, int totalMarks) {
    final percentage = marks / totalMarks;
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

class _StudentView extends StatefulWidget {
  final String taskId;
  final String classroomId;
  final int totalMarks;
  const _StudentView({required this.taskId, required this.classroomId, required this.totalMarks});

  @override
  State<_StudentView> createState() => _StudentViewState();
}

class _StudentViewState extends State<_StudentView> {
  File? _submissionFile;
  bool _isSubmitting = false;

  Future<void> _pickFile() async {
    final pickedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (pickedFile != null) {
      setState(() => _submissionFile = File(pickedFile.files.single.path!));
    }
  }

  Future<void> _submitTask() async {
    if (_submissionFile == null) return;
    setState(() => _isSubmitting = true);

    try {
      final ref = FirebaseStorage.instance.ref().child(
          "submissions/${DateTime.now().millisecondsSinceEpoch}.${_submissionFile!.path.split('.').last}");
      await ref.putFile(_submissionFile!);
      final fileUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection("Classrooms")
          .doc(widget.classroomId)
          .collection("Tasks")
          .doc(widget.taskId)
          .collection("Submissions")
          .add({
        "studentId": FirebaseAuth.instance.currentUser!.uid,
        "fileUrl": fileUrl,
        "submittedAt": Timestamp.now(),
        "marksObtained":null,
        "feedback":'',
        "isGraded": false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Submitted successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("Classrooms")
          .doc(widget.classroomId)
          .collection("Tasks")
          .doc(widget.taskId)
          .collection("Submissions")
          .where("studentId", isEqualTo: user.uid)
          .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final hasSubmission = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
          final submission = hasSubmission ? snapshot.data!.docs.first : null;

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Submission",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  if (hasSubmission) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.assignment, color: Colors.deepPurple),
                      title: Text("Submitted file"),
                      subtitle: Text(submission!["fileUrl"].split('/').last),
                      trailing: IconButton(
                        icon: Icon(Icons.download, color: Colors.deepPurple),
                        onPressed: () => launchUrl(Uri.parse(submission["fileUrl"])),
                      ),
                    ),

                    if (submission["isGraded"]) ...[
                      Divider(),
                      _buildGradeIndicator(
                        submission["marksObtained"],
                        widget.totalMarks,
                        submission["feedback"],
                      ),
                    ],
                    SizedBox(height: 16),
                    Text(
                      "Submitted on ${DateFormat('MMM dd, yyyy').format(submission["submittedAt"].toDate())}",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ] else ...[
                    Text(
                      "You haven't submitted anything yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: Icon(Icons.upload),
                      label: Text(_submissionFile == null
                          ? "Upload Submission"
                          : "Selected: ${_submissionFile!.path.split('/').last}"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    if (_submissionFile != null) ...[
                      SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitTask,
                        icon: _isSubmitting
                            ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Icon(Icons.send),
                        label: Text(_isSubmitting ? "Submitting..." : "Submit"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
    );
  }

  Widget _buildGradeIndicator(int marks, int totalMarks, String? feedback) {
    final percentage = (marks / totalMarks) * 100;
    Color color;
    if (percentage >= 80) {
      color = Colors.green;
    } else if (percentage >= 50) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Grade",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: color.withOpacity(0.2),
          color: color,
          minHeight: 12,
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Text(
              "$marks/$totalMarks",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(width: 16),
            if (feedback != null)
              Expanded(
                child: Text(
                  '"$feedback"',
                  style: TextStyle(fontStyle: FontStyle.italic),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ],
    );
  }
}