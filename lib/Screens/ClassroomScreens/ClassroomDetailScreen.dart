import 'dart:io';
import 'package:classroom/Providers/classroom_provider.dart';
import 'package:classroom/Providers/task_Provider.dart';
import 'package:classroom/Screens/ClassroomScreens/CreateTaskScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../Models/task_model.dart';
import '../../Utils/page_animations.dart';
import 'CreateClassroomScreen.dart';
import 'TaskDetailsScreen.dart';
import 'package:http/http.dart' as http;


class ClassroomDetailsScreen extends StatefulWidget {
  final String className;
  final String classroomId;
  final String joinCode;
  final String classDescription;
  final String classImageURL;

  const ClassroomDetailsScreen({super.key, required this.classroomId, required this.className, required this.joinCode, required this.classDescription, required this.classImageURL});

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
    if(mounted) {
      setState(() {
      _isModerator = classroom["createdBy"] == FirebaseAuth.instance.currentUser!.uid;
    });
    }
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
            MembersTab(classroomCode: widget.joinCode,
              className: widget.className,profileImageUrl: widget.classImageURL,
              classDescription: widget.classDescription,
            ),


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
                onTap: () async {

                  Navigator.pop(context);

                  final message =
                      "👋 Hey! Join classroom *${widget.className}* using code: *${widget.joinCode}* on our EduNest app.";
                  final subject = "Classroom Invite";

                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) {
                      return Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: Colors.blue),
                              const SizedBox(height: 16),
                              Text(
                                "Preparing your invite...",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );

                  try {
                    if (widget.classImageURL.isNotEmpty) {
                      try {
                        final response = await http.get(Uri.parse(widget.classImageURL));
                        if (response.statusCode == 200) {
                          final tempDir = await getTemporaryDirectory();
                          final file = File('${tempDir.path}/classroom.jpg');
                          await file.writeAsBytes(response.bodyBytes);

                          Navigator.pop(context); // Close loading dialog

                          await Share.shareXFiles(
                            [XFile(file.path)],
                            text: message,
                            subject: subject,
                          );
                          return;
                        }
                      } catch (e) {
                        debugPrint("Image download failed: $e");
                      }
                    }

                    Navigator.pop(context); // Close loading dialog

                    // Fallback: Share text only
                    await Share.share(
                      message,
                      subject: subject,
                    );
                  } catch (e) {
                    Navigator.pop(context); // Ensure dialog is closed on error
                    debugPrint("Sharing failed: $e");
                  }
                }
              ),
              if (_isModerator)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text("Remove Classroom"),
                  onTap: () async {
                    Navigator.pop(context);

                    final provider = Provider.of<ClassroomProvider>(context, listen: false);

                    final confirmed = await _confirmDelete(context);
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
              if(_isModerator)
                ListTile(
                  leading: Icon(Icons.edit, color: Colors.blueAccent),
                  title: Text("Edit Classroom"),
                  onTap: (){
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        CustomPageTransitions.fade(
                            CreateClassroomScreen(
                              isEditing: true,
                              classroomId: widget.classroomId,
                              existingName: widget.className,
                              existingDescription: widget.classDescription,
                              existingImageUrl: widget.classImageURL,

                        ))
                    );
                  },

                ),
              if (!_isModerator)
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.redAccent),
                  title: Text("Leave Classroom"),
                  onTap: () async {
                    try {
                      final confirmed =
                          await _confirmDelete(context, isDelete: false);

                      if (confirmed == true) {
                        await FirebaseFirestore.instance
                            .collection("Classrooms")
                            .doc(widget.classroomId)
                            .update({
                          "members": FieldValue.arrayRemove([user.uid]),
                        });

                        if (mounted) {
                          Navigator.pop(context);// close sheet
                          Navigator.pop(context);//go back to home
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("Successfully left the class")),
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint("Leaving failed: $e");
                    }
                  },
                )
            ],
          ),
        );
      },
    );
  }


  Future<bool?> _confirmDelete(BuildContext context, {isDelete = true}) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(
          isDelete?"Delete Classroom":"Leave Classroom",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
          ),
        ),
        content: Text(
          isDelete?"Are you sure you want to delete this classroom and all tasks?":"Are you sure you want to Leave this classroom",
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
              isDelete ?"Delete" : "Leave",
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
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/no_task.png'),
              Text("This is where you’ll assign work"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0,vertical: 10),
                child: Text("You can add assignments and other work for the class, then organize it into topics",textAlign: TextAlign.center,style: TextStyle(color: Colors.grey,),),
              ),
            ],
          );
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
        onTap: () {
          Navigator.push(
              context,
              CustomPageTransitions.fade(
                  TaskDetailsScreen(
                taskId: task.id,
                classroomId: classRoomID,
                isModerator: isModerator,
              ))
          );
        } ,
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
  final String classroomCode;
  final String className;
  final String profileImageUrl;
  final String classDescription;

  const MembersTab({
    super.key,
    required this.classroomCode, required this.className, required this.profileImageUrl, required this.classDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Always show Add Students card

            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 20),
              child: ListTile(
                leading: const Icon(Icons.person_add, color: Colors.blue),
                title: const Text(
                  "Add Students",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Share classroom code: $classroomCode"),
                  trailing: IconButton(
                    icon: const Icon(Icons.share, color: Colors.blue),
                    onPressed: () async {
                      final message =
                          "👋 Hey! Join classroom *$className* using code: *$classroomCode* on our EduNest app.";
                      final subject = "Classroom Invite";

                      // Show loading dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) {
                          return Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(color: Colors.blue),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Preparing your invite...",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );

                      try {
                        if (profileImageUrl.isNotEmpty) {
                          try {
                            final response = await http.get(Uri.parse(profileImageUrl));
                            if (response.statusCode == 200) {
                              final tempDir = await getTemporaryDirectory();
                              final file = File('${tempDir.path}/classroom.jpg');
                              await file.writeAsBytes(response.bodyBytes);

                              Navigator.pop(context); // Close loading dialog

                              await Share.shareXFiles(
                                [XFile(file.path)],
                                text: message,
                                subject: subject,
                              );
                              return;
                            }
                          } catch (e) {
                            debugPrint("Image download failed: $e");
                          }
                        }

                        Navigator.pop(context); // Close loading dialog

                        // Fallback: Share text only
                        await Share.share(
                          message,
                          subject: subject,
                        );
                      } catch (e) {
                        Navigator.pop(context); // Ensure dialog is closed on error
                        debugPrint("Sharing failed: $e");
                      }
                    },
                  )


              ),
            ),

            // Teachers Section
            if (provider.teachers.isNotEmpty) ...[
              const Text(
                "Teacher",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...provider.teachers.map((user) => ListTile(
                leading: _buildAvatar(user),
                title: Text(user['username'] ?? "UnKnown"),
                subtitle: Text(user['email'] ?? ""),
              )),
              const SizedBox(height: 20),
            ],

            // Students Section
            const Text(
              "Students",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (provider.students.isEmpty)
               Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    SizedBox(height: 50,),
                    Image.asset('assets/empty_student.png'),
                    Text(
                      "No students yet",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              )
            else
              ...provider.students.map((user) => ListTile(
                leading: _buildAvatar(user),
                title: Text(user['username'] ?? "Unnamed"),
                subtitle: Text(user['email'] ?? ""),
              )),
          ],
        );
      },
    );
  }

  Widget _buildAvatar(Map<String, dynamic> user) {
    final profileImage = user['profileImageURL'];
    if (profileImage != null && profileImage.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(profileImage));
    }
    return CircleAvatar(
      backgroundColor: Colors.blueAccent,
      child: Text(
        (user['username']?.isNotEmpty ?? false)
            ? user['username'][0].toUpperCase()
            : '?',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}


