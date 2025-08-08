import 'package:classroom/Providers/classroom_provider.dart';
import 'package:classroom/Providers/task_Provider.dart';
import 'package:classroom/Screens/ClassroomScreens/CreateTaskScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../Models/task_model.dart';
import 'TaskDetailsScreen.dart';


class ClassroomDetailsScreen extends StatefulWidget {
  final String className;
  final String classroomId;
  final String joinCode;
  const ClassroomDetailsScreen({super.key, required this.classroomId, required this.className, required this.joinCode});

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
    return ChangeNotifierProvider(
      create: (_) => TaskProvider(classroomId: widget.classroomId),
      child: Scaffold(
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
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.white),
              onPressed: () => _showOptionsBottomSheet(context),
            ),
          ],

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
            TasksTab(isModerator: _isModerator,classRoomID: widget.classroomId,),
            MembersTab(),


          ],
        ),
        floatingActionButton: _isModerator?  FloatingActionButton(

            onPressed: (){

              TaskModel taskData= TaskModel(
                  id: '', title: '', description: '', dueDate: DateTime.now(), marks: 0, fileName: '');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateTaskScreen(
                classroomId: widget.classroomId, taskData: taskData,
              ),
            ),
          );

        },
          child: Icon(Icons.add)): null,
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.share, color: Colors.deepPurple),
                title: Text("Share Class Code"),
                onTap: () {
                  Navigator.pop(context);
                  final message = "👋 Hey! Join classroom *${widget.className}* using code: *${widget.joinCode}* on our EduNest app.";
                  Clipboard.setData(ClipboardData(text: message));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Join code copied to clipboard!")),
                  );
                },
              ),
              if (_isModerator)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text("Remove Classroom"),
                  onTap: () async {
                    Navigator.pop(context);

                    final provider = Provider.of<ClassroomProvider>(context, listen: false);

                    final confirmed = await _confirmDelete(context);
                    debugPrint(confirmed.toString());
                    if (confirmed == true) {

                      await provider.deleteAllTasksAndClassroom(widget.classroomId);
                      if (mounted) Navigator.pop(context);// Close details screen
                      //to go back on home
                      if (mounted) Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Successfully removed your class")),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }


  Future<bool?> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Classroom",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this classroom and all tasks?",
          style: GoogleFonts.poppins(),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
           onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              "Delete",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }


}

class TasksTab extends StatelessWidget {
  final bool isModerator;
  final String classRoomID;
  const TasksTab({super.key, required this.isModerator, required this.classRoomID});

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
            classRoomID: classRoomID,
          ),
        );
      },
    );
  }
}


class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final String classRoomID;
  final bool isModerator;
  const _TaskCard({required this.task, required this.isModerator, required this.classRoomID});

  @override
  Widget build(BuildContext context) {
    final dueDate = task.dueDate;
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
              classroomId: classRoomID,
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
                        task.title.toString(),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20, color: Colors.deepPurple),
                                const SizedBox(width: 8),
                                Text(
                                  "Edit",
                                  style: GoogleFonts.poppins(),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red[400]),
                                const SizedBox(width: 8),
                                Text(
                                  "Delete",
                                  style: GoogleFonts.poppins(),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _navigateToEditTask(context);
                          } else if (value == 'delete') {
                            final shouldDelete = await _showDeleteConfirmation(context);
                            if (shouldDelete ?? false) {
                              await Provider.of<TaskProvider>(context,listen: false).deleteTask(task.id, task.fileUrl);
                            }
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  task.description,
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
                      "${task.marks} pts",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.amber[400],
                      ),
                    ),
                  ],
                ),
                if (task.fileUrl != null) ...[
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
          classroomId: classRoomID,
          taskData: task ,
          isEditing: true,
        ),
      ),
    );
  }



  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Task",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this task? This action cannot be undone.",
          style: GoogleFonts.poppins(),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              "Delete",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class MembersTab extends StatelessWidget {
  const MembersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
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
