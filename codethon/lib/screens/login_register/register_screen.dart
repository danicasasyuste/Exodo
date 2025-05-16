import 'package:codethon/screens/login_register/google_sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:codethon/widgets/btn.dart';
import 'package:codethon/widgets/square_tile.dart';
import 'package:codethon/widgets/textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Sign user up method
  void signUserUp() async {
    // Show loading circle
    showDialog(
      context: context,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Check if passwords match
      if (passwordController.text != confirmPasswordController.text) {
        Navigator.pop(context);
        showErrorMessage("Las contraseñas no coinciden!");
        return;
      }

      // Try creating the user
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Pop the loading circle
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Close the loading circle
      print("Firebase Error: ${e.message}");
      showErrorMessage(e.message ?? "Ocurrió un error desconocido");
    }
  }

  // Error message to user
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.deepOrange,
          title: Center(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Lottie.asset(
              'assets/lottie/day-time.json',
              fit: BoxFit.cover,
              repeat: true,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.25),
                    // Welcome back
                    Text(
                      'Bienvenido, te estamos esperando!',
                      style: TextStyle(
                        color: Colors.grey.shade100,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // Email text field
                    MyTextField(
                      controller: emailController,
                      hintText: 'Email',
                      obsecureText: false,
                    ),

                    SizedBox(height: screenHeight * 0.01),

                    // Password text field
                    MyTextField(
                      controller: passwordController,
                      hintText: 'Contraseña',
                      obsecureText: true,
                    ),

                    SizedBox(height: screenHeight * 0.01),

                    // Confirm password text field
                    MyTextField(
                      controller: confirmPasswordController,
                      hintText: 'Confirmar contraseña',
                      obsecureText: true,
                    ),

                    SizedBox(height: screenHeight * 0.01),

                    SizedBox(height: screenHeight * 0.02),

                    // Sign-in button
                    MyButton(
                      onTap: signUserUp, 
                      text: "Crear Cuenta",
                    ),

                    SizedBox(height: screenHeight * 0.04),

                    // Or continue with
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 0.5,
                              color: Colors.grey.shade100,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                            ),
                            child: Text(
                              'O continuar con',
                              style: TextStyle(
                                color: Colors.grey.shade100,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 0.5,
                              color: Colors.grey.shade100,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.04),

                    // Google + Apple buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            GoogleSignInProvider.signInWithGoogle();
                          },
                          child: const SizedBox(
                            width: 50,
                            height: 50,
                            child: SquareTile(
                              imagePath: 'assets/images/google.png',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.04),

                    // Not a member? Register now
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿Ya tienes una cuenta?',
                          style: TextStyle(
                            color: Colors.grey.shade100,
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: widget.onTap ?? () {},
                          child: Text(
                            'Iniciar sesion',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 76, 161, 184),
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.04),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
