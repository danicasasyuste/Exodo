import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../login_register/login_or_register_screen.dart';
import '../weather_screen.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // user is logged in
          if(snapshot.hasData) {
            return WeatherScreen();
          } 
          // user is NOT logged in
          else {
            return LoginOrRegisterPage();
          }
        }
      ),
    );
  }
}
