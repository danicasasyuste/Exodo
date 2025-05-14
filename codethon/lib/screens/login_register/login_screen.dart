import 'dart:async';
import 'package:codethon/widgets/btn.dart';
import 'package:codethon/screens/login_register/password_recovery_screen.dart';
import 'package:codethon/widgets/global_btn_status.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:codethon/widgets/square_tile.dart';
import 'package:codethon/widgets/textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:codethon/screens/login_register/google_sign_in_screen.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GlobalConfig.ocultarAsistente();
    });
  }

  void signUserIn() async {
    // Mostrar la animación Lottie como diálogo
    final navigator = Navigator.of(context);
    final dialogContextCompleter = Completer<BuildContext>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        if (!dialogContextCompleter.isCompleted) {
          dialogContextCompleter.complete(context);
        }
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Lottie.asset(
              'assets/lottie/intro.json',
              width: 180,
              onLoaded: (composition) async {
                // Wait for the animation to finish
                await Future.delayed(composition.duration);

                // Proceed with login logic after the animation
                if (dialogContextCompleter.isCompleted) {
                  final dialogContext = await dialogContextCompleter.future;

                  // Close the dialog
                  Navigator.of(dialogContext).pop();

                  // Perform login logic
                  try {
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: emailController.text,
                      password: passwordController.text,
                    );

                    // Navigate to the next screen or show success
                    navigator
                        .pop(); // Close the login screen or navigate elsewhere
                  } on FirebaseAuthException catch (e) {
                    showErrorMessage(e.code);
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.deepOrange,
          title: Center(
            child: Text(message, style: TextStyle(color: Colors.white)),
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
              'assets/lottie/background-cycle.json',
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
                    SizedBox(height: screenHeight * 0.05),

                    SizedBox(
                      height: 165,
                      child: Center(
                        child: Lottie.asset(
                          'assets/lottie/day-night.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    Text(
                      'Bienvenido, te hemos extrañado!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    MyTextField(
                      controller: emailController,
                      hintText: 'Email',
                      obsecureText: false,
                    ),

                    SizedBox(height: screenHeight * 0.015),

                    MyTextField(
                      controller: passwordController,
                      hintText: 'Contaseña',
                      obsecureText: true,
                    ),

                    SizedBox(height: screenHeight * 0.01),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PasswordRecoveryPage(),
                                ),
                              );
                            },
                            child: Text(
                              '¿Olvidó la contraseña?',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    MyButton(onTap: signUserIn, text: "Iniciar sesión"),

                    SizedBox(height: screenHeight * 0.04),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 0.5,
                              color: Colors.white70,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                            ),
                            child: Text(
                              'O continuar con',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 0.5,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.04),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            GoogleSignInProvider.signInWithGoogle();
                          },
                          child: SizedBox(
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No eres un miembro?',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: widget.onTap ?? () {},
                          child: Text(
                            'Registrate ahora',
                            style: TextStyle(
                              color: Colors.lightBlueAccent.shade400,
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
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
