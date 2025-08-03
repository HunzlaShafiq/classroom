import 'package:classroom/Providers/classroom_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../Utils/Components/my_button.dart';

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
  String? _imageUrl;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _classImage = File(pickedFile.path));
    }
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Classroom"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back_ios_new,color: Colors.white,)),

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
                      ? const Icon(Icons.camera_alt,color: Colors.deepPurpleAccent, size: 40)
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

              Consumer<ClassroomProvider>(
                  builder: (context,providerValue,child) {
                    return MyButton(
                        text: "Create Classroom",
                        onPressed: (){
                          if (!_formKey.currentState!.validate()) return;

                          providerValue.createClassroom(
                              _classNameController.text,
                              _classDescController.text,
                              _classImage,
                              context);
                        },
                        isLoading: providerValue.isLoading,
                        horizontalPadding: 50, verticalPadding: 15);
                  }
              ),

            ],
          ),
        ),
      ),
    );
  }
}