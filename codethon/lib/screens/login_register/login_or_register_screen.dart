import 'package:flutter/material.dart';
import '../login_register/login_screen.dart';
import '../login_register/register_screen.dart';

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  // Initially show login page
  bool showLoginPage = true;

  // toggle between login and register page
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }
  @override
  Widget build(BuildContext context) {
    if(showLoginPage) {
      return LoginPage(
        onTap: togglePages,
      );
    } else {
      return RegisterPage(
        onTap: togglePages,
      );
    }
  }
}
