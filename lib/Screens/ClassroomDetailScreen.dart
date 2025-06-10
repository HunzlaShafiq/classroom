import 'package:classroom/Screens/CreateTaskScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'TaskDetailsScreen.dart';

class ClassroomDetailsScreen extends StatefulWidget {
  final String classroomId;
  const ClassroomDetailsScreen({super.key, required this.classroomId});

  @override
  State<ClassroomDetailsScreen> createState() => _ClassroomDetailsScreenState();
}

class _ClassroomDetailsScreenState extends State<ClassroomDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final user = FirebaseAuth.instance.currentUser!;
  bool _isModerator = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkModeratorStatus();
  }

  Future<void> _checkModeratorStatus() async {
    final classroom = await FirebaseFirestore.instance
        .collection("Classrooms")
        .doc(widget.classroomId)
        .get();
    setState(() {
      _isModerator = classroom["createdBy"] == FirebaseAuth.instance.currentUser!.uid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("Classrooms")
              .doc(widget.classroomId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text("Classroom");
            return Text(snapshot.data!["className"]);
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.assignment)),
            Tab(icon: Icon(Icons.people)),
          ],
        ),
        actions: _isModerator
            ? [
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateTaskScreen(
                        classroomId: widget.classroomId,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                ),
              ]
            : null,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Tasks
          _TasksTab(classroomId: widget.classroomId, isModerator: _isModerator),
          // Tab 2: Members
          _MembersTab(classroomId: widget.classroomId),
        ],
      ),
    );
  }
}

// Tab 1: Tasks List
class _TasksTab extends StatelessWidget {
  final String classroomId;
  final bool isModerator;
  const _TasksTab({required this.classroomId, required this.isModerator});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("Classrooms")
          .doc(classroomId)
          .collection("Tasks")
          .orderBy("dueDate")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No tasks yet!"));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final task = snapshot.data!.docs[index];
            return _TaskCard(task: task, isModerator: isModerator);
          },
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final QueryDocumentSnapshot task;
  final bool isModerator;
  const _TaskCard({required this.task, required this.isModerator});

  @override
  Widget build(BuildContext context) {
    final dueDate = task["dueDate"].toDate();
    final isOverdue = dueDate.isBefore(DateTime.now());
    final daysRemaining = dueDate.difference(DateTime.now()).inDays;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailsScreen(
              taskId: task.id,
              classroomId: task.reference.parent.parent!.id,
              isModerator: isModerator,
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey[900]!,
                Colors.grey[850]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task["title"],
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isModerator)
                      PopupMenuButton(
                        icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20, color: Colors.grey[700]),
                                const SizedBox(width: 8),
                                Text("Edit"),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red[400]),
                                const SizedBox(width: 8),
                                Text("Delete"),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _navigateToEditTask(context);
                          } else if (value == 'delete') {
                            _deleteTask();
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  task["description"],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      isOverdue
                          ? "Overdue ${DateFormat('MMM dd').format(dueDate)}"
                          : "Due in $daysRemaining days",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isOverdue ? Colors.red[400] : Colors.grey[400],
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.star, size: 16, color: Colors.amber[400]),
                    const SizedBox(width: 4),
                    Text(
                      "${task["marks"]} pts",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.amber[400],
                      ),
                    ),
                  ],
                ),
                if (task["fileUrl"] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.attach_file, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        "Has attachment",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.blue[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToEditTask(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTaskScreen(
          classroomId: task.reference.parent.parent!.id,
          taskData: task.data() as Map<String, dynamic>,
          isEditing: true,
        ),
      ),
    );
  }

  Future<void> _deleteTask() async {
    await task.reference.delete();
  }
}

// Tab 2: Members List
class _MembersTab extends StatelessWidget {
  final String classroomId;
  const _MembersTab({required this.classroomId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("Classrooms")
          .doc(classroomId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final members = snapshot.data!["members"] as List<dynamic>;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("Users3")
                  .doc(members[index])
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const ListTile(title: Text("Loading..."));
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(userSnapshot.data!["username"][0]),
                  ),
                  title: Text(userSnapshot.data!["username"]),
                  subtitle: Text(userSnapshot.data!["email"]),
                );
              },
            );
          },
        );
      },
    );
  }
}