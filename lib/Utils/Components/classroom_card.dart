import 'package:classroom/Screens/ClassroomScreens/ClassroomDetailScreen.dart';
import 'package:classroom/Utils/page_animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ClassroomCard extends StatelessWidget {
  final DocumentSnapshot classroom;
  final String classroomId;

  const ClassroomCard({super.key, required this.classroom, required this.classroomId});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(context,
              CustomPageTransitions.bottomUp(
                  ClassroomDetailsScreen(
                  className:classroom["className"],

                  classroomId: classroomId, joinCode: classroom['joinCode'],)
              )
          );
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