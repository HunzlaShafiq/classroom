import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

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

  void _gradeSubmission(BuildContext context, QueryDocumentSnapshot submission, String userName) {
    final _marksController = TextEditingController(
      text: submission["marksObtained"]?.toString() ?? "",
    );
    final _feedbackController = TextEditingController(
      text: submission["feedback"] ?? "",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Draggable Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Grade Submission",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple[300],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[400]),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Student Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple[800],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            userName.substring(0, 1).toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: Colors.deepPurple[100],
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Student",
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              userName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Marks Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _marksController,
                    decoration: InputDecoration(
                      labelText: "Enter Marks",
                      labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                      hintText: "0-100",
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple[900],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.grade, color: Colors.deepPurple[300]),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[800],
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 12),

                // Feedback Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _feedbackController,
                    decoration: InputDecoration(
                      labelText: "Feedback",
                      labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                      hintText: "Write your feedback here...",
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber[900],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.feedback, color: Colors.amber[300]),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[800],
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                    ),
                    maxLines: 3,
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_marksController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Please enter marks"),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: Colors.amber[800],
                            ),
                          );
                          return;
                        }

                        try {
                          await submission.reference.update({
                            "marksObtained": int.parse(_marksController.text),
                            "feedback": _feedbackController.text,
                            "isGraded": true,
                            "gradedAt": FieldValue.serverTimestamp(),
                          });

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  const Text("Submission graded successfully!"),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: Colors.green[800],
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text("Error: ${e.toString()}"),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.deepPurple[800],
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Submit Grade",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Task Details",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back_ios_new,color: Colors.white,)),

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
  final Function(BuildContext, QueryDocumentSnapshot,String) onGrade;

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
                  child: Column(
                    children: [
                      Image.asset("assets/no_submit.png"),
                      Text(
                        "No submissions yet",
                        style: GoogleFonts.poppins(),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
                                child: _buildAvatar(userSnapshot.data!),
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
                                    submission["fileName"],
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


                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove_red_eye, color: Colors.teal),
                                  onPressed: () => _previewFile(context, submission["fileUrl"]),
                                  tooltip: 'Preview submission',
                                ),
                                IconButton(
                                  icon: Icon(Icons.download, color: Colors.deepPurple),
                                  onPressed: () => _downloadFile(context, submission["fileUrl"]),
                                  tooltip: 'Download submission',
                                ),
                                if (submission["isGraded"])
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => onGrade(context, submission,userSnapshot.data!["username"]),
                                    tooltip: 'Edit grade',
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: () => onGrade(context, submission,userSnapshot.data!["username"]),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      padding: EdgeInsets.symmetric(horizontal: 15),
                                    ),
                                    child: Text("Grade"),
                                  ),
                              ],
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

  Widget _buildAvatar(DocumentSnapshot user) {
    final profileImage = user['profileImageURL'];
    if (profileImage != null && profileImage.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(profileImage));
    }
    return CircleAvatar(
      backgroundColor: Colors.blueAccent,
      child: Text(
        (user['username']?.isNotEmpty ?? false)
            ? user['username'][0].toUpperCase()
            : '?',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Future<void> _previewFile(BuildContext context, String url) async {
    try {
      final previewUrl = _getPreviewUrl(url);

      final uri = Uri.parse(previewUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // open in browser
        );
      } else {
        throw 'Could not launch preview';
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

  /// Generates preview URL for supported file types
  String _getPreviewUrl(String fileUrl) {
    final lower = fileUrl.toLowerCase();

    // Supported formats via Google Docs Viewer
    if (lower.endsWith('.pdf') ||
        lower.endsWith('.doc') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.ppt') ||
        lower.endsWith('.pptx') ||
        lower.endsWith('.xls') ||
        lower.endsWith('.xlsx')) {
      return "https://docs.google.com/viewer?embedded=true&url=$fileUrl";
    }

    // For images and other direct viewable files
    return fileUrl;
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
        "fileName":p.basename(_submissionFile!.path),
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
              padding: EdgeInsets.symmetric(vertical: 16,horizontal: 50),
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
                      subtitle: Text(submission!["fileName"]),
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