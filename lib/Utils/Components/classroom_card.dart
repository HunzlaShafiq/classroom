import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Screens/ClassroomScreens/ClassroomDetailScreen.dart';
import '../page_animations.dart';

class ClassroomCard extends StatelessWidget {
  final DocumentSnapshot classroom;
  final String classroomId;

  const ClassroomCard({
    super.key,
    required this.classroom,
    required this.classroomId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            CustomPageTransitions.rightToLeft(
              ClassroomDetailsScreen(
                className: classroom["className"],
                classroomId: classroomId,
                joinCode: classroom['joinCode'],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Classroom Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getClassColor(classroom["className"]),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  classroom["className"].substring(0, 1).toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Classroom Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classroom["className"],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      classroom["classDescription"] ?? "No description",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Menu Button
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                onPressed: () {
                  // Add classroom options menu
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getClassColor(String className) {
    final colors = [
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.red.shade700,
      Colors.orange.shade700,
      Colors.purple.shade700,
      Colors.teal.shade700,
    ];
    return colors[className.hashCode % colors.length];
  }
}