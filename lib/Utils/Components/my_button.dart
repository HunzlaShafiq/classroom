import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyButton extends StatelessWidget {

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final double horizontalPadding;
  final double verticalPadding;

  const MyButton({super.key,
    required this.text,
    required this.onPressed,
    this.isLoading =false,
    required this.horizontalPadding,
    required this.verticalPadding});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding:  EdgeInsets.symmetric(
            horizontal: horizontalPadding, vertical: verticalPadding),
      ),
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.deepPurple,)
          : Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 18,
          color: Colors.deepPurple,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
