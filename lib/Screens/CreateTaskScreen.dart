import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';

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
        title: Text(widget.isEditing ? "Edit Task" : "Create Task"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Title"),
                validator: (value) => value!.isEmpty ? "Enter title" : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
              TextFormField(
                controller: _marksController,
                decoration: InputDecoration(labelText: "Marks"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Enter marks" : null,
              ),
              ListTile(
                title: Text(_dueDate == null
                    ? "Select Due Date"
                    : "Due: ${DateFormat('MMM dd, yyyy').format(_dueDate!)}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDueDate,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickFile,
                child: Text(_taskFile == null
                    ? "Upload Task File (PDF/DOC)"
                    : "File Selected: ${_taskFile!.path.split('/').last}"),
              ),
              if (_fileUrl != null && _taskFile == null)
                Text("Current File: ${_fileUrl!.split('/').last}"),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTask,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50)),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(widget.isEditing ? "Update Task" : "Create Task"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}