import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:classroom/Providers/profile_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ProfileScreen({super.key, required this.userData});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _userData;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isImageLoading = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String _imageUrl = "";

  @override
  void initState() {
    super.initState();
    _userData = widget.userData;
    _nameController = TextEditingController(text: _userData['username']);
    _emailController = TextEditingController(text: _userData['email']);
    _phoneController = TextEditingController(text: _userData['phone'] ?? '');
    _imageUrl = _userData['profileImageURL'] ?? '';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _isImageLoading = true);
      try {
        final ref = FirebaseStorage.instance.ref().child('Users3/${picked.name}');
        await ref.putFile(File(picked.path));
        _imageUrl = await ref.getDownloadURL();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
        );
      } finally {
        setState(() => _isImageLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final updatedData = {
        'username': _nameController.text,
        'phone': _phoneController.text,
        'profileImageURL': _imageUrl,
      };
      await FirebaseFirestore.instance.collection('Users3').doc(uid).update(updatedData);
      setState(() {
        _userData = {..._userData, ...updatedData};
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSaving = false);
      Map<String, dynamic>?  userData={
        'username': _nameController.text,
        'phone': _phoneController.text,
        'profileImageURL': _imageUrl,
        'email':widget.userData['email'],
        'createdAt':widget.userData['createdAt']
      };

      Provider.of<ProfileProvider>(context,listen: false).updateUserData(userData);

    }
  }

  void _toggleEditMode() {
    if (_isEditing) {
      // Reset to original values if cancelling edit
      _nameController.text = _userData['username'];
      _phoneController.text = _userData['phone'] ?? '';
      _imageUrl = _userData['profileImageURL'] ?? '';
    }
    setState(() => _isEditing = !_isEditing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back_ios_new,color: Colors.white,)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit,color: Colors.white,),
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfilePicture(),
            const SizedBox(height: 32),
            _isEditing ? _buildEditForm() : _buildProfileInfo(),
            if (_isEditing) ...[
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ],
        ),
      ),
    );
  }



  Widget _buildProfilePicture() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.deepPurple,
              width: 2,
            ),
          ),
          child: _imageUrl.isNotEmpty
              ? ClipOval(
            child: CachedNetworkImage(
              imageUrl: _imageUrl,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.person, size: 60, color: Colors.deepPurple),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.error_outline, color: Colors.red),
              ),
            ),
          )
              : CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, size: 60, color: Colors.deepPurple),
          ),
        ),
        if (_isImageLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
          ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }


  Widget _buildProfileInfo() {
    return Column(
      children: [
        _buildInfoTile(Icons.person, 'Name', _userData['username']),
        const SizedBox(height: 16),
        _buildInfoTile(Icons.email, 'Email', _userData['email']),
        const SizedBox(height: 16),
        _buildInfoTile(Icons.phone, 'Phone', _userData['phone'] ?? 'Not provided'),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_outlined,
          enabled: false, // Email shouldn't be editable
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: Colors.black87),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.poppins(color: Colors.black54),
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : Text(
          'SAVE CHANGES',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}