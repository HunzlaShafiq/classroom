import 'package:classroom/Providers/auth_provider.dart';
import 'package:classroom/Utils/Components/my_button.dart';
import 'package:classroom/Utils/Components/my_text_field.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  "Reset Password",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                MyTextField(controller: _emailController, label: "Email", iconData: Icons.email),
                const SizedBox(height: 30),

                Consumer<AuthProviders>(
                    builder: (context,providerValue,child) {
                      return MyButton(
                          text: "Login",
                          onPressed: (){
                            providerValue.resetPassword(email: _emailController.text,context: context);
                          },
                          isLoading: providerValue.isLoading,
                          horizontalPadding: 50, verticalPadding: 15);
                    }
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}