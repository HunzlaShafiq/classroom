import 'package:classroom/Models/classroom_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Screens/ClassroomScreens/ClassroomDetailScreen.dart';
import '../page_animations.dart';

import 'package:cached_network_image/cached_network_image.dart';


class ClassroomCard extends StatelessWidget {
  final Classroom classroom;
  final String classroomId;

  const ClassroomCard({
    super.key,
    required this.classroom,
    required this.classroomId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = _getClassColor(classroom.className, colorScheme);
    final hasImage = classroom.classImageUrl.toString().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            CustomPageTransitions.rightToLeft(
              ClassroomDetailsScreen(
                className: classroom.className,
                classroomId: classroomId,
                joinCode: classroom.joinCode,
                classDescription: classroom.classDescription,
                classImageURL: classroom.classImageUrl,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with optional image or colored accent
            if (hasImage)
              ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: classroom.classImageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: cardColor.withOpacity(0.2),
                      height: 120,),
                      errorWidget: (context, url, error) => _buildColorHeader(cardColor),
                    ),
                  )
                  else
                  _buildColorHeader(cardColor),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Classroom Avatar (circular with image or initial)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          image: hasImage
                              ? DecorationImage(
                            image: CachedNetworkImageProvider(
                                classroom.classImageUrl),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: hasImage
                            ? null
                            : Center(
                          child: Text(
                            classroom.className.substring(0, 1).toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: cardColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Class Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classroom.className,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Class Code: ${classroom.joinCode}",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description
                  if (classroom.classDescription.toString().isNotEmpty)
                    Text(
                      classroom.classDescription,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 12),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorHeader(Color color) {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
    );
  }


  Color _getClassColor(String className, ColorScheme colorScheme) {
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.teal.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
    ];
    return colors[className.hashCode % colors.length];
  }
}