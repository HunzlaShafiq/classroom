import 'package:classroom/Providers/classroom_provider.dart';
import 'package:classroom/Providers/members_provider.dart';
import 'package:classroom/Providers/task_Provider.dart';
import 'package:classroom/Screens/ClassroomScreens/CreateTaskScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../Models/task_model.dart';


class ClassroomDetailsScreen extends StatefulWidget {
  final String className;
  final String classroomId;
  const ClassroomDetailsScreen({super.key, required this.classroomId, required this.className});

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
        title: Text(
          widget.className,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back_ios_new,color: Colors.white,)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.assignment)),
            Tab(icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Tasks
          ChangeNotifierProvider(
              create: (_) => TaskProvider(classroomId: widget.classroomId),
            child: TasksTab(isModerator: _isModerator),
          ),

          ChangeNotifierProvider(
            create: (_) => MemberProvider(classroomId: widget.classroomId),
            child:MembersTab(),
          ),

        ],
      ),
      floatingActionButton: _isModerator?  FloatingActionButton(

          onPressed: (){

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateTaskScreen(
              classroomId: widget.classroomId,
            ),
          ),
        );

      },
        child: Icon(Icons.add)): null,
    );
  }
}

class TasksTab extends StatelessWidget {
  final bool isModerator;
  const TasksTab({super.key, required this.isModerator});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.tasks.isEmpty) {
          return const Center(child: Text("No tasks yet!"));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.tasks.length,
          itemBuilder: (context, index) => _TaskCard(
            task: provider.tasks[index],
            isModerator: isModerator,
          ),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isModerator;
  const _TaskCard({required this.task, required this.isModerator});

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.dueDate.isBefore(DateTime.now());
    final daysRemaining = task.dueDate.difference(DateTime.now()).inDays;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[900]!, Colors.grey[850]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(task.title,
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                  if (isModerator)
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text("Edit")),
                        const PopupMenuItem(value: 'delete', child: Text("Delete")),
                      ],
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await Provider.of<TaskProvider>(context, listen: false).deleteTask(task.id);
                        }
                      },
                    )
                ],
              ),
              const SizedBox(height: 8),
              Text(task.description, style: GoogleFonts.poppins(color: Colors.white70)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    isOverdue ? "Overdue" : "Due in $daysRemaining days",
                    style: GoogleFonts.poppins(color: isOverdue ? Colors.red[300] : Colors.grey[300]),
                  ),
                  const Spacer(),
                  Icon(Icons.star, size: 16, color: Colors.amber[400]),
                  const SizedBox(width: 4),
                  Text("${task.marks} pts", style: GoogleFonts.poppins(color: Colors.amber[400]))
                ],
              ),
              if (task.fileUrl != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_file, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text("Has attachment", style: GoogleFonts.poppins(color: Colors.blue[300]))
                  ],
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class MembersTab extends StatelessWidget {
  const MembersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MemberProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.membersData.length,
          itemBuilder: (context, index) {
            final user = provider.membersData[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(user['username'][0]),
              ),
              title: Text(user['username']),
              subtitle: Text(user['email']),
            );
          },
        );
      },
    );
  }
}
