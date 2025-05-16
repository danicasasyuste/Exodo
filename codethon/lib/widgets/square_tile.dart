import 'package:flutter/material.dart';

class SquareTile extends StatelessWidget {
  final String imagePath;
  const SquareTile({
    super.key, 
    required this.imagePath,
    });
//  
@override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70),
        borderRadius: BorderRadius.circular(16),
        color: const Color.fromARGB(179, 239, 239, 239),
        ),
      child: Image.asset(
        imagePath,
        height: 30,
        width: 30,
        fit: BoxFit.cover,
        ),
    );
  }
}
