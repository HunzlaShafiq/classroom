import 'package:cached_network_image/cached_network_image.dart';
import 'package:classroom/Screens/ClassroomScreens/CreateClassroomScreen.dart';
import 'package:classroom/Screens/AuthScreens/LogInScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../Providers/classroom_provider.dart';
import '../Utils/Components/classroom_card.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser!;

  Map<String, dynamic>? _userData;
  bool _isUserLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("Users3")
          .doc(user.uid)
          .get();

      if (snapshot.exists) {
        setState(() {
          _userData = snapshot.data();
          _isUserLoading = false;
        });
      }
    } catch (e) {
      print("Failed to fetch user data: $e");
    }
  }


  Future<void> _confirmLogout(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // User can tap outside to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Confirm Logout",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
            ),
          ),
          content: Text(
            "Are you sure you want to logout?",
            style: GoogleFonts.poppins(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(
                  color: Colors.grey[700],
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                "Logout",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: _buildDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            return GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _isUserLoading
                    ? const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white),
                )
                    : _userData?['profileImageURL'] != null &&
                            _userData!['profileImageURL'].toString().isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(
                              _userData!['profileImageURL'],
                            ),
                          )
                        : const CircleAvatar(
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
              ),
            );
          },
        ),
      ),
      body: Consumer<ClassroomProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color:Colors.deepPurple ,));
          }

          if (provider.classrooms.isEmpty) {
            return Center(
              child: Text(
                "No classrooms yet!\nCreate or join one.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 18),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: provider.classrooms.length,
            itemBuilder: (context, index) {
              final classroom = provider.classrooms[index];
              return ClassroomCard(
                classroom: classroom,
                classroomId: classroom.id,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showClassroomOptions,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }


  void _showClassroomOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.create, color: Colors.white),
                title: Text(
                  "Create Classroom",
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToCreateClassroom();
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add, color: Colors.white),
                title: Text(
                  "Join Classroom",
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showJoinClassroomDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToCreateClassroom() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateClassroomScreen()),
    );
  }

  void _showJoinClassroomDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Join Classroom", style: GoogleFonts.poppins()),
          content: TextField(
            controller: codeController,
            decoration: InputDecoration(
              labelText: "Enter 6-digit Code",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => _joinClassroom(codeController.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: const Text("Join", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinClassroom(String code) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection("Classrooms")
          .where("joinCode", isEqualTo: code)
          .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid code!")),
        );
        return;
      }

      final classroom = query.docs.first;
      await FirebaseFirestore.instance
          .collection("Classrooms")
          .doc(classroom.id)
          .update({
        "members": FieldValue.arrayUnion([user.uid]),
      });

      // Update user's joinedClassrooms list
      await FirebaseFirestore.instance
          .collection("Users3")
          .doc(user.uid)
          .update({
        "joinedClassrooms": FieldValue.arrayUnion([classroom.id]),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Joined successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Widget _buildDrawer() {
    final profileImageUrl = _userData?['profileImageURL'] ?? '';
    final username = _userData?['username'] ?? 'User';
    final email = _userData?['email'] ?? 'user@example.com';

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF512DA8), Color(0xFF536DFE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage: profileImageUrl.isNotEmpty
                    ? CachedNetworkImageProvider(profileImageUrl)
                    : null,
                child: profileImageUrl.isEmpty
                    ? const Icon(Icons.person, size: 50, color: Colors.deepPurple)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    username,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Divider(color: Colors.white38, thickness: 1),
            Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text(
                "Logout",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmLogout(context);
              },
            ),
          ],
        ),
      ),
    );
  }


}

