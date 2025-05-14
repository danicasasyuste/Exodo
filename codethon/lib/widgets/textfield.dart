import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {

  final controller;
  final String hintText;
  final bool obsecureText;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obsecureText,
    });

  @override
    Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: TextField(
          controller: controller,
          obscureText: obsecureText,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
              ),
              focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
              ),
              fillColor: const Color.fromARGB(179, 239, 239, 239),
              filled: true,
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.black38)
        ),
      ),
    );
  }
}


