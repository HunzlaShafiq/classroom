import 'package:classroom/Screens/ClassroomScreens/ClassroomDetailScreen.dart';
import 'package:classroom/Screens/ClassroomScreens/CreateClassroomScreen.dart';
import 'package:classroom/Screens/AuthScreens/LogInScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser!;

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
      appBar: AppBar(
        title: Text(
          "My Classrooms",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _confirmLogout(context),
            icon: Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("Classrooms")
            .where("members", arrayContains: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final classroom = snapshot.data!.docs[index];
              return _ClassroomCard(classroom: classroom,classroomId: snapshot.data!.docs[index].id,);
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
    final _codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Join Classroom", style: GoogleFonts.poppins()),
          content: TextField(
            controller: _codeController,
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
              onPressed: () => _joinClassroom(_codeController.text.trim()),
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
}

class _ClassroomCard extends StatelessWidget {
  final QueryDocumentSnapshot classroom;
  final String classroomId;

  const _ClassroomCard({required this.classroom, required this.classroomId});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context)=>ClassroomDetailsScreen(classroomId: classroomId)));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: classroom["classImageUrl"] != null
                    ? Image.network(
                  classroom["classImageUrl"],
                  fit: BoxFit.cover,
                )
                    : Container(
                  color: Colors.deepPurple[100],
                  child: const Icon(Icons.class_, size: 50),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classroom["className"],
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    classroom["classDescription"] ?? "No description",
                    style: GoogleFonts.poppins(color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}