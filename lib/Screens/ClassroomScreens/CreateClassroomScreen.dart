import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';

class CreateClassroomScreen extends StatefulWidget {
  const CreateClassroomScreen({super.key});

  @override
  State<CreateClassroomScreen> createState() => _CreateClassroomScreenState();
}

class _CreateClassroomScreenState extends State<CreateClassroomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _classDescController = TextEditingController();
  File? _classImage;
  bool _isLoading = false;
  String? _imageUrl;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _classImage = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImage() async {
    if (_classImage == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("classroom_images/${DateTime.now().millisecondsSinceEpoch}.jpg");
      await ref.putFile(_classImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e")),
      );
      return null;
    }
  }

  Future<void> _createClassroom() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Upload image (if selected)
      _imageUrl = await _uploadImage();

      // 2. Generate random 6-digit join code
      final joinCode = _generateJoinCode();

      // 3. Save to Firestore
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection("Classrooms").add({
        "className": _classNameController.text.trim(),
        "classDescription": _classDescController.text.trim(),
        "classImageUrl": _imageUrl,
        "createdBy": user.uid,
        "createdAt": Timestamp.now(),
        "joinCode": joinCode,
        "members": [user.uid], // Creator is first member
      });

      // 4. Update user's joined classrooms
      await FirebaseFirestore.instance.collection("Users3").doc(user.uid).update({
        "joinedClassrooms": FieldValue.arrayUnion([]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Classroom created!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Classroom"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _classImage != null
                      ? FileImage(_classImage!)
                      : (_imageUrl != null ? NetworkImage(_imageUrl!) : null),
                  child: _classImage == null && _imageUrl == null
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _classNameController,
                decoration: InputDecoration(
                  labelText: "Class Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? "Enter class name" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _classDescController,
                decoration: InputDecoration(
                  labelText: "Description (Optional)",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _createClassroom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  "Create Classroom",
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}