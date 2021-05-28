import 'package:flutter/material.dart';

class GradientText extends StatelessWidget {
  final size;
  bool underline = false;
  final FontWeight weight;

  GradientText(
    this.text, {
    @required this.gradient,
    @required this.size,
    this.underline,
        this.weight,
  });

  final String text;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: TextStyle(
          // The color must be set to white for this to work
          color: Colors.white,
          fontSize: size,
          decoration: underline == true ? TextDecoration.underline : null,
          fontWeight: weight != null ? weight : null,
        ),
      ),
    );
  }
}
