import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

class ClassroomShareWidget extends StatefulWidget {
  final String className;
  final String classCode;
  final String? profileImageUrl;
  final String classDescription;

  const ClassroomShareWidget({
    super.key,
    required this.className,
    required this.classCode,
    required this.classDescription,
    this.profileImageUrl,
  });

  @override
  State<ClassroomShareWidget> createState() => _ClassroomShareWidgetState();
}

class _ClassroomShareWidgetState extends State<ClassroomShareWidget> {
  final GlobalKey _globalKey = GlobalKey();

  Future<void> _shareClassroom() async {
    try {
      // 1️⃣ Convert widget to image
      RenderRepaintBoundary boundary =
      _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 2️⃣ Save to temp directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/classroom_invite.png');
      await file.writeAsBytes(pngBytes);

      // 3️⃣ Share image + text
      final message =
          "👋 Hey! Join classroom *${widget.className}* using code: *${widget.classCode}* on EduNest app.";
      await Share.shareXFiles(
        [XFile(file.path)],
        text: message,
        subject: "Classroom Invite",
      );
    } catch (e) {
      debugPrint("Error sharing classroom: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RepaintBoundary(
          key: _globalKey,
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: (widget.profileImageUrl != null &&
                      widget.profileImageUrl!.isNotEmpty)
                      ? NetworkImage(widget.profileImageUrl!)
                      : const AssetImage('assets/classroomLogo.png')
                  as ImageProvider,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.className,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold,color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.classDescription,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Join Code: ${widget.classCode}",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "📅 ${DateFormat('MMM dd, yyyy').format(DateTime.now())}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                 Text(
                  "📲 Download EduNest App to Join!",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400,fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.share),
          label: const Text("Share Classroom Invite"),
          onPressed: _shareClassroom,
        ),
      ],
    );
  }
}
