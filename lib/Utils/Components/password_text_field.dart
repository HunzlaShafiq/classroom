import 'package:flutter/material.dart';

class PasswordTextField extends StatelessWidget {

  final TextEditingController controller;
  final String label;
  final bool isObscure;
  final VoidCallback onPressedObscure;

  const PasswordTextField({super.key, required this.controller, required this.label, required this.isObscure, required this.onPressedObscure});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(Icons.lock, color: Colors.white70),
        suffixIcon: IconButton(
            onPressed: onPressedObscure,
            icon: isObscure?  Icon(Icons.visibility, color: Colors.white70):
            Icon(Icons.visibility_off, color: Colors.white70)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }
}
