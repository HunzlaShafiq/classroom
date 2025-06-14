import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateTaskScreen extends StatefulWidget {
  final String classroomId;
  final Map<String, dynamic>? taskData;
  final bool isEditing;
  const CreateTaskScreen({
    super.key,
    required this.classroomId,
    this.taskData,
    this.isEditing = false,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _marksController = TextEditingController();
  DateTime? _dueDate;
  File? _taskFile;
  bool _isLoading = false;
  String? _fileUrl;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.taskData != null) {
      _titleController.text = widget.taskData!["title"];
      _descController.text = widget.taskData!["description"];
      _marksController.text = widget.taskData!["marks"].toString();
      _dueDate = widget.taskData!["dueDate"].toDate();
      _fileUrl = widget.taskData!["fileUrl"];
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          _taskFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking file: $e")),
      );
    }
  }

  Future<String?> _uploadFile() async {
    if (_taskFile == null) return _fileUrl;
    try {
      final ref = FirebaseStorage.instance.ref().child(
          "task_files/${DateTime.now().millisecondsSinceEpoch}.${_taskFile!.path.split('.').last}");
      await ref.putFile(_taskFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload file: $e")),
      );
      return null;
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate() || _dueDate == null) return;
    setState(() => _isLoading = true);

    try {
      final fileUrl = await _uploadFile();
      final taskData = {
        "title": _titleController.text.trim(),
        "description": _descController.text.trim(),
        "marks": int.parse(_marksController.text.trim()),
        "dueDate": Timestamp.fromDate(_dueDate!),
        "fileUrl": fileUrl,
        "createdBy": FirebaseAuth.instance.currentUser!.uid,
        "createdAt": Timestamp.now(),
      };

      if (widget.isEditing) {
        await FirebaseFirestore.instance
            .collection("Classrooms")
            .doc(widget.classroomId)
            .collection("Tasks")
            .doc(widget.taskData!["taskId"])
            .update(taskData);
      } else {
        await FirebaseFirestore.instance
            .collection("Classrooms")
            .doc(widget.classroomId)
            .collection("Tasks")
            .add(taskData);
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() => _dueDate = pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? "Edit Task" : "Create New Task",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade800,
              Colors.deepPurple.shade500,
              Colors.deepPurple.shade300,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Task Title Card
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
                        Text(
                          "Task Details",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: "Task Title",
                            labelStyle: TextStyle(color: Colors.deepPurple),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.deepPurple),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.deepPurple,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.title,
                              color: Colors.deepPurple,
                            ),
                          ),
                          style: GoogleFonts.poppins(),
                          validator: (value) =>
                          value!.isEmpty ? "Please enter a title" : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: "Description",
                            labelStyle: TextStyle(color: Colors.deepPurple),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.deepPurple),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.deepPurple,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.description,
                              color: Colors.deepPurple,
                            ),
                          ),
                          style: GoogleFonts.poppins(),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Task Requirements Card
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
                        Text(
                          "Task Requirements",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _marksController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Total Marks",
                            labelStyle: TextStyle(color: Colors.deepPurple),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.deepPurple),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.deepPurple,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.star,
                              color: Colors.deepPurple,
                            ),
                          ),
                          style: GoogleFonts.poppins(),
                          validator: (value) =>
                          value!.isEmpty ? "Please enter marks" : null,
                        ),
                        SizedBox(height: 16),
                        InkWell(
                          onTap: _selectDueDate,
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.deepPurple),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.deepPurple,
                                ),
                                SizedBox(width: 16),
                                Text(
                                  _dueDate == null
                                      ? "Select Due Date"
                                      : "Due: ${DateFormat('MMM dd, yyyy').format(_dueDate!)}",
                                  style: GoogleFonts.poppins(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // File Attachment Card
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
                        Text(
                          "Task Attachment",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        SizedBox(height: 16),
                        if (_fileUrl != null && _taskFile == null)
                          Column(
                            children: [
                              ListTile(
                                leading: Icon(
                                  Icons.attach_file,
                                  color: Colors.deepPurple,
                                ),
                                title: Text(
                                  "Current File",
                                  style: GoogleFonts.poppins(),
                                ),
                                subtitle: Text(
                                  _fileUrl!.split('/').last,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              SizedBox(height: 8),
                            ],
                          ),
                        ElevatedButton(
                          onPressed: _pickFile,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.deepPurple, backgroundColor: Colors.deepPurple.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_file),
                              SizedBox(width: 8),
                              Text(
                                _taskFile == null
                                    ? "Upload Task File (PDF/DOC)"
                                    : "Selected: ${_taskFile!.path.split('/').last}",
                              ),
                            ],
                          ),
                        ),
                        if (_taskFile != null) ...[
                          SizedBox(height: 8),
                          Text(
                            "New file selected for upload",
                            style: TextStyle(
                              color: Colors.green,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                        : Text(
                      widget.isEditing ? "UPDATE TASK" : "CREATE TASK",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}