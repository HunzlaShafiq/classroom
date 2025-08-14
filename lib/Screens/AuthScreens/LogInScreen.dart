import 'package:classroom/Providers/auth_provider.dart';
import 'package:classroom/Screens/AuthScreens/ForgetPasswordScreen.dart';
import 'package:classroom/Utils/Components/my_button.dart';
import 'package:classroom/Utils/Components/my_text_field.dart';
import 'package:classroom/Utils/Components/password_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Services/logout_login_services.dart';
import 'SignUpScreen.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  ValueNotifier<bool> isObscureNotifier = ValueNotifier(true);





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome Back!",
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                MyTextField(controller: _emailController, label: 'Email', iconData: Icons.email),
                const SizedBox(height: 20),
                ValueListenableBuilder(
                  valueListenable: isObscureNotifier,
                  builder: (context,isObscure,_) {
                    return PasswordTextField(
                        controller: _passwordController, label: "Password", isObscure: isObscure,
                      onPressedObscure: () => isObscureNotifier.value = !isObscure ,
                    );
                  }
                ),

                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    ),
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Consumer<AuthProviders>(
                  builder: (context,providerValue,child) {
                    return MyButton(
                        text: "Login",
                        onPressed: (){
                          providerValue.login(_emailController.text, _passwordController.text, context);
                          LogoutLoginServices().loginRefreshData(context);
                        },
                        isLoading: providerValue.isLoading,
                        horizontalPadding: 50, verticalPadding: 15);
                  }
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  ),
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: const TextStyle(color: Colors.white70),
                      children: [
                        TextSpan(
                          text: "Sign Up",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}