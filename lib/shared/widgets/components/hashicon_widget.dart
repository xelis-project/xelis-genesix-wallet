import 'package:flutter/material.dart';
import 'package:flutter_hashicon/hashicon.dart';

class HashiconWidget extends StatelessWidget {
  final String hash;
  final Size size;

  const HashiconWidget({super.key, required this.hash, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: HashiconPainter(hash: hash),
      size: size,
    );
  }
}
