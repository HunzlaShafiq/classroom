import 'package:classroom/Providers/classroom_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../Utils/Components/my_button.dart';

class CreateClassroomScreen extends StatefulWidget {
  final bool isEditing;
  final String? classroomId;
  final String? existingName;
  final String? existingDescription;
  final String? existingImageUrl;

  const CreateClassroomScreen({
    super.key,
    this.isEditing = false,
    this.classroomId,
    this.existingName,
    this.existingDescription,
    this.existingImageUrl,
  });

  @override
  State<CreateClassroomScreen> createState() => _CreateClassroomScreenState();
}

class _CreateClassroomScreenState extends State<CreateClassroomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _classDescController = TextEditingController();
  File? _classImage;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();

    // If editing, pre-fill the form
    if (widget.isEditing) {
      _classNameController.text = widget.existingName ?? "";
      _classDescController.text = widget.existingDescription ?? "";
      _imageUrl = widget.existingImageUrl;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _classImage = File(pickedFile.path);
        _imageUrl = null; // Remove old image preview if new picked
      });
    }
  }

  void _handleSave(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<ClassroomProvider>(context, listen: false);

    if (widget.isEditing) {
      provider.updateClassroom(
        classroomId: widget.classroomId!,
        className: _classNameController.text,
        description: _classDescController.text,
        newImageFile: _classImage,
        existingImageUrl: _imageUrl,
        context: context,
      );
    } else {
      provider.createClassroom(
        _classNameController.text,
        _classDescController.text,
        _classImage,
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        Text(widget.isEditing ? "Edit Classroom" : "Create Classroom"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
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
                      : (_imageUrl != null && _imageUrl!.isNotEmpty
                      ? NetworkImage(_imageUrl!)
                      : null) as ImageProvider?,
                  child: _classImage == null && (_imageUrl == null || _imageUrl!.isEmpty)
                      ? const Icon(Icons.camera_alt,
                      color: Colors.deepPurpleAccent, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _classNameController,
                decoration: const InputDecoration(
                  labelText: "Class Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? "Enter class name" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _classDescController,
                decoration: const InputDecoration(
                  labelText: "Description (Optional)",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              Consumer<ClassroomProvider>(
                builder: (context, providerValue, child) {
                  return MyButton(
                    text: widget.isEditing ? "Update Classroom" : "Create Classroom",
                    onPressed: () => _handleSave(context),
                    isLoading: providerValue.isLoading,
                    horizontalPadding: 50,
                    verticalPadding: 15,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
