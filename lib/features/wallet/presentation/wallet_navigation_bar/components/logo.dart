import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  const Logo({super.key, required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Image.asset(imagePath, fit: BoxFit.cover),
    );
  }
}
